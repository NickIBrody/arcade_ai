import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/chat.dart';
import '../models/llm_provider.dart';

class StreamDelta {
  final String text;
  final String reasoning;
  const StreamDelta({this.text = '', this.reasoning = ''});
}

class LlmException implements Exception {
  final String message;
  LlmException(this.message);
  @override
  String toString() => message;
}

class LlmClient {
  final http.Client _http = http.Client();

  Stream<StreamDelta> stream({
    required LlmProvider provider,
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    required GenerationConfig config,
    Map<String, String> extras = const {},
  }) {
    switch (provider.format) {
      case ApiFormat.anthropic:
        return _anthropic(provider, apiKey, model, history, config);
      case ApiFormat.openai:
      default:
        return _openaiCompatible(provider, apiKey, model, history, config);
    }
  }

  // ---- OpenAI-compatible (OpenAI, Gemini, Groq, DeepSeek, Mistral, xAI,
  //      OpenRouter, Together, Cohere-compat, Ollama, custom) ----
  Stream<StreamDelta> _openaiCompatible(
    LlmProvider p,
    String key,
    String model,
    List<ChatMessage> history,
    GenerationConfig cfg,
  ) async* {
    final uri = Uri.parse('${_trim(p.baseUrl)}/chat/completions');
    final messages = <Map<String, dynamic>>[];
    if (cfg.systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': cfg.systemPrompt});
    }
    for (final m in history) {
      if (m.images.isNotEmpty && m.role == Role.user) {
        messages.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': m.text},
            ...m.images.map((a) => {
                  'type': 'image_url',
                  'image_url': {'url': a.dataUri},
                }),
          ],
        });
      } else {
        messages.add({'role': m.role.name, 'content': m.text});
      }
    }

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': cfg.temperature,
      'max_tokens': cfg.maxTokens,
      'stream': cfg.stream,
    });

    final req = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        if (key.isNotEmpty) 'Authorization': 'Bearer $key',
      })
      ..body = body;

    final res = await _http.send(req);
    if (res.statusCode >= 400) {
      throw LlmException(await _errorText(res));
    }

    if (!cfg.stream) {
      final json = jsonDecode(await res.stream.bytesToString());
      final msg = (json['choices'] as List?)?.first?['message']
          as Map<String, dynamic>?;
      final text = msg?['content'] as String? ?? '';
      final reasoning = (msg?['reasoning_content'] ?? msg?['reasoning'])
              as String? ??
          '';
      yield StreamDelta(text: text, reasoning: reasoning);
      return;
    }

    await for (final line in _sseLines(res)) {
      if (line == '[DONE]') return;
      final json = _tryJson(line);
      if (json == null) continue;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) continue;
      final delta = choices.first['delta'] as Map<String, dynamic>?;
      if (delta == null) continue;
      final text = delta['content'] as String? ?? '';
      final reasoning = (delta['reasoning_content'] ?? delta['reasoning'])
              as String? ??
          '';
      if (text.isNotEmpty || reasoning.isNotEmpty) {
        yield StreamDelta(text: text, reasoning: reasoning);
      }
    }
  }

  // ---- Anthropic Messages API ----
  Stream<StreamDelta> _anthropic(
    LlmProvider p,
    String key,
    String model,
    List<ChatMessage> history,
    GenerationConfig cfg,
  ) async* {
    final uri = Uri.parse('${_trim(p.baseUrl)}/messages');
    final messages = <Map<String, dynamic>>[];
    for (final m in history.where((m) => m.role != Role.system)) {
      if (m.images.isNotEmpty && m.role == Role.user) {
        messages.add({
          'role': 'user',
          'content': [
            ...m.images.map((a) => {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': a.mime,
                    'data': a.base64,
                  },
                }),
            {'type': 'text', 'text': m.text},
          ],
        });
      } else {
        messages.add({'role': m.role.name, 'content': m.text});
      }
    }

    final body = jsonEncode({
      'model': model,
      'max_tokens': cfg.maxTokens,
      'temperature': cfg.temperature,
      if (cfg.systemPrompt.trim().isNotEmpty) 'system': cfg.systemPrompt,
      'messages': messages,
      'stream': cfg.stream,
    });

    final req = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      })
      ..body = body;

    final res = await _http.send(req);
    if (res.statusCode >= 400) {
      throw LlmException(await _errorText(res));
    }

    if (!cfg.stream) {
      final json = jsonDecode(await res.stream.bytesToString());
      final blocks = json['content'] as List? ?? [];
      final textBuf = StringBuffer();
      final thinkBuf = StringBuffer();
      for (final b in blocks) {
        if (b['type'] == 'text') {
          textBuf.write(b['text'] ?? '');
        } else if (b['type'] == 'thinking') {
          thinkBuf.write(b['thinking'] ?? '');
        }
      }
      yield StreamDelta(text: textBuf.toString(), reasoning: thinkBuf.toString());
      return;
    }

    await for (final line in _sseLines(res)) {
      final json = _tryJson(line);
      if (json == null) continue;
      final type = json['type'];
      if (type == 'content_block_delta') {
        final d = json['delta'] as Map<String, dynamic>?;
        if (d == null) continue;
        if (d['type'] == 'text_delta') {
          yield StreamDelta(text: d['text'] ?? '');
        } else if (d['type'] == 'thinking_delta') {
          yield StreamDelta(reasoning: d['thinking'] ?? '');
        }
      } else if (type == 'error') {
        throw LlmException(json['error']?['message'] ?? 'Anthropic error');
      }
    }
  }

  // ---- helpers ----
  Stream<String> _sseLines(http.StreamedResponse res) async* {
    final lines = res.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty || line.startsWith(':')) continue;
      if (line.startsWith('data:')) {
        yield line.substring(5).trim();
      }
    }
  }

  Map<String, dynamic>? _tryJson(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _errorText(http.StreamedResponse res) async {
    final raw = await res.stream.bytesToString();
    try {
      final j = jsonDecode(raw);
      final msg = j['error']?['message'] ?? j['message'] ?? j['error'];
      if (msg != null) return '${res.statusCode}: $msg';
    } catch (_) {}
    return 'HTTP ${res.statusCode}: ${raw.isEmpty ? 'no body' : raw}';
  }

  String _trim(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  void dispose() => _http.close();
}
