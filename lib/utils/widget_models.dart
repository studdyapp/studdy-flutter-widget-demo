//Not to be tampered with
//---Contains the core classes for the Studdy Widget

import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Exception thrown when authentication request validation fails
class WidgetAuthException implements Exception {
  final String message;
  WidgetAuthException(this.message);
  
  @override
  String toString() => 'WidgetAuthException: $message';
}

/// Exception thrown when page data validation fails
class PageDataException implements Exception {
  final String message;
  PageDataException(this.message);
  
  @override
  String toString() => 'PageDataException: $message';
}

/// Exception thrown when data validation fails
class WidgetDataException implements Exception {
  final String message;
  WidgetDataException(this.message);
  
  @override
  String toString() => 'WidgetDataException: $message';
}

/// Class representing authentication request parameters for StuddyWidget
class WidgetAuthRequest {
  final String tenantId;
  final String authMethod;
  final String? jwt;
  final String? version;

  WidgetAuthRequest({
    required this.tenantId,
    required this.authMethod,
    this.jwt,
    this.version = "1.0",
  }) {
    // Basic validation
    if (tenantId.isEmpty) {
      throw WidgetDataException('tenantId cannot be empty');
    }
    if (authMethod.isEmpty) {
      throw WidgetDataException('authMethod cannot be empty');
    }
    if (authMethod == 'jwt' && (jwt == null || jwt!.isEmpty)) {
      throw WidgetDataException('jwt is required when authMethod is "jwt"');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'tenantId': tenantId,
      'authMethod': authMethod,
      'version': version,
    };
    
    // Add jwt if it exists
    if (jwt != null) {
      json['jwt'] = jwt;
    }
    
    return json;
  }
}

/// Authentication result returned after successful authentication
class WidgetAuthResult {
  final String userId;
  final String tenantId;

  WidgetAuthResult({
    required this.userId,
    required this.tenantId,
  });

  factory WidgetAuthResult.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('userId') || !json.containsKey('tenantId')) {
      throw WidgetAuthException('Invalid authentication result format');
    }
    
    return WidgetAuthResult(
      userId: json['userId'],
      tenantId: json['tenantId'],
    );
  }
}

/// Union type for content (either file or text)
abstract class Content {
  void validate();
  Map<String, dynamic> toJson();
  
  static Content fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('type')) {
      throw PageDataException('Content missing required type field');
    }
    
    switch (json['type']) {
      case 'image':
        if (!json.containsKey('file_data') || 
            !json['file_data'].containsKey('file_uri') || 
            !json['file_data'].containsKey('mime_type')) {
          throw PageDataException('FileContent has invalid format');
        }
        return FileContent(
          fileUri: json['file_data']['file_uri'],
          mimeType: json['file_data']['mime_type'],
        );
      case 'text':
        if (!json.containsKey('text')) {
          throw PageDataException('TextContent missing required text field');
        }
        return TextContent(text: json['text']);
      default:
        throw PageDataException('Unknown content type: ${json['type']}');
    }
  }
}

/// Class representing file content
class FileContent implements Content {
  final String type = 'image';
  final Map<String, String> fileData;

  FileContent({
    required String fileUri,
    required String mimeType,
  }) : fileData = {
          'file_uri': fileUri,
          'mime_type': mimeType,
        };

  @override
  void validate() {
    if (fileData['file_uri'] == null || fileData['file_uri']!.isEmpty) {
      throw PageDataException('fileUri cannot be empty for FileContent');
    }
    if (fileData['mime_type'] == null || fileData['mime_type']!.isEmpty) {
      throw PageDataException('mimeType cannot be empty for FileContent');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'file_data': fileData,
    };
  }
}

/// Class representing text content
class TextContent implements Content {
  final String type = 'text';
  final String text;

  TextContent({required this.text});

  @override
  void validate() {
    if (text.isEmpty) {
      throw PageDataException('text cannot be empty for TextContent');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
    };
  }
}

/// Class representing a choice option
class ChoiceOption {
  final String? label;
  final List<Content> contents;

  ChoiceOption({
    this.label,
    required this.contents,
  });

  void validate() {
    if (contents.isEmpty) {
      throw PageDataException('ChoiceOption must have at least one content item');
    }
    
    for (final content in contents) {
      content.validate();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (label != null) 'label': label,
      'contents': contents.map((c) => c.toJson()).toList(),
    };
  }
}

/// Class representing a problem object
class ProblemObject {
  final String problemId;
  final String referenceTitle;
  final List<Content> problemStatement;
  final List<ChoiceOption>? solutionOptions;
  final String? correctAnswerReferenceId;
  final Map<String, dynamic> metaData;

  ProblemObject({
    required this.problemId,
    required this.referenceTitle,
    required this.problemStatement,
    this.solutionOptions,
    this.correctAnswerReferenceId,
    required this.metaData,
  });

  void validate() {
    if (problemId.isEmpty) {
      throw PageDataException('problemId cannot be empty');
    }
    if (referenceTitle.isEmpty) {
      throw PageDataException('referenceTitle cannot be empty');
    }
    if (problemStatement.isEmpty) {
      throw PageDataException('problemStatement must have at least one content item');
    }
    
    for (final content in problemStatement) {
      content.validate();
    }
    
    if (solutionOptions != null) {
      for (final option in solutionOptions!) {
        option.validate();
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'problemId': problemId,
      'referenceTitle': referenceTitle,
      'problemStatement': problemStatement.map((c) => c.toJson()).toList(),
      if (solutionOptions != null) 
        'solutionOptions': solutionOptions!.map((o) => o.toJson()).toList(),
      if (correctAnswerReferenceId != null) 
        'correctAnswerReferenceId': correctAnswerReferenceId,
      'metaData': metaData,
    };
  }
}

/// Class representing page data for StuddyWidget
class PageData {
  final List<Map<String, dynamic>> problems;
  final String? targetLocale;

  PageData({required this.problems, this.targetLocale}) {
    // Basic validation
    if (problems.isEmpty) {
      throw WidgetDataException('problems list cannot be empty');
    }
    
    // Validate each problem has minimum required fields
    for (final problem in problems) {
      if (!problem.containsKey('problemId')) {
        throw WidgetDataException('A problem is missing "problemId" field');
      }
      if (!problem.containsKey('referenceTitle')) {
        throw WidgetDataException('A problem is missing "referenceTitle" field');
      }
      if (!problem.containsKey('problemStatement')) {
        throw WidgetDataException('A problem is missing "problemStatement" field');
      }
    }
  }

  /// Static helper to create PageData from JSON string
  static PageData fromJsonString(String jsonString) {
    try {
      final dynamic parsed = jsonDecode(jsonString);
      
      if (parsed is List) {
        // It's a list of problems directly
        return PageData(
          problems: List<Map<String, dynamic>>.from(parsed),
          targetLocale: null,
        );
      } else if (parsed is Map<String, dynamic>) {
        // It's a complete PageData object
        if (!parsed.containsKey('problems')) {
          throw WidgetDataException('Missing required field: problems');
        }
        
        final problemsList = parsed['problems'];
        if (problemsList is! List) {
          throw WidgetDataException('Problems must be a list');
        }
        
        return PageData(
          problems: List<Map<String, dynamic>>.from(problemsList),
          targetLocale: parsed['targetLocale'] as String?,
        );
      } else {
        throw WidgetDataException('Invalid JSON format');
      }
    } catch (e) {
      if (e is WidgetDataException) rethrow;
      throw WidgetDataException('Error parsing JSON: ${e.toString()}');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'problems': problems,
      if (targetLocale != null) 'targetLocale': targetLocale,
    };
  }
} 