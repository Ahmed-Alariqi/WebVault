import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

class PageContentExtractor {
  /// Extracts the visible text, title, and meta description from the given WebViewController.
  static Future<Map<String, String>> extractPageData(WebViewController controller) async {
    const jsCode = '''
      (function() {
        const title = document.title || "";
        const url = window.location.href || "";
        let metaDescription = "";
        const metaTags = document.getElementsByTagName('meta');
        for (let i = 0; i < metaTags.length; i++) {
          if (metaTags[i].name === 'description') {
            metaDescription = metaTags[i].content;
            break;
          }
        }
        
        // Smart visible text extraction
        let clone = document.body.cloneNode(true);
        const selectorsToRemove = ['script', 'style', 'nav', 'header', 'footer', 'noscript', 'iframe', '.ad', '.ads', '.advertisement', '#ads'];
        selectorsToRemove.forEach(sel => {
            const elements = clone.querySelectorAll(sel);
            elements.forEach(el => el.remove());
        });
        
        // Remove empty lines and excessive spaces
        let bodyText = clone.innerText || "";
        bodyText = bodyText.replace(/\\n\\s*\\n/g, '\\n').trim();
        
        return JSON.stringify({
          title: title,
          url: url,
          description: metaDescription,
          content: bodyText.substring(0, 15000) // Keep generous amount for detailed pages like W3Schools
        });
      })();
    ''';

    try {
      final result = await controller.runJavaScriptReturningResult(jsCode);
      // Evaluate the returned JSON string - it might come back wrapped in extra quotes from iOS/Android bridge
      String jsonStr = result.toString();
        // Remove surrounding quotes and unescape if it's double serialized
        if (jsonStr.startsWith("'") && jsonStr.endsWith("'")) {
          jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        } else if (jsonStr.startsWith('"') && jsonStr.endsWith('"') && jsonStr.contains('\\"')) {
           try {
             jsonStr = jsonDecode(jsonStr) as String;
           } catch (_) {}
        }
        
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return {
          'title': data['title']?.toString() ?? '',
          'url': data['url']?.toString() ?? '',
          'description': data['description']?.toString() ?? '',
          'content': data['content']?.toString() ?? '',
        };
    } catch (e) {
      // Return empty if extraction fails
    }
    
    return {
      'title': '',
      'url': '',
      'description': '',
      'content': '',
    };
  }
}
