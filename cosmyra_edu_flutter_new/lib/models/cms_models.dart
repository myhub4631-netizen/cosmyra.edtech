import 'dart:convert';

/// CMS Page Model
class CmsPageModel {
  final String id;
  final String slug;
  final String title;
  final String content;
  final String contentFormat; // 'markdown', 'html'
  final String status; // 'draft', 'published'
  final String? seoTitle;
  final String? metaDescription;
  final String? featuredImageUrl;
  final bool isSystem;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  CmsPageModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    this.contentFormat = 'markdown',
    this.status = 'draft',
    this.seoTitle,
    this.metaDescription,
    this.featuredImageUrl,
    this.isSystem = false,
    this.authorName = 'Cosmyra Admin',
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';

  factory CmsPageModel.fromJson(Map<String, dynamic> json) {
    return CmsPageModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      contentFormat: json['content_format']?.toString() ?? 'markdown',
      status: json['status']?.toString() ?? 'draft',
      seoTitle: json['seo_title']?.toString(),
      metaDescription: json['meta_description']?.toString(),
      featuredImageUrl: json['featured_image_url']?.toString(),
      isSystem: json['is_system'] == true,
      authorName: json['author_name']?.toString() ?? 'Cosmyra Admin',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'slug': slug.trim().toLowerCase(),
      'title': title.trim(),
      'content': content,
      'content_format': contentFormat,
      'status': status,
      'seo_title': seoTitle?.trim(),
      'meta_description': metaDescription?.trim(),
      'featured_image_url': featuredImageUrl?.trim(),
      'is_system': isSystem,
      'author_name': authorName,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    if (status == 'published') {
      map['published_at'] = publishedAt?.toIso8601String() ?? DateTime.now().toIso8601String();
    } else {
      map['published_at'] = null;
    }
    return map;
  }

  CmsPageModel copyWith({
    String? id,
    String? slug,
    String? title,
    String? content,
    String? contentFormat,
    String? status,
    String? seoTitle,
    String? metaDescription,
    String? featuredImageUrl,
    bool? isSystem,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return CmsPageModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      content: content ?? this.content,
      contentFormat: contentFormat ?? this.contentFormat,
      status: status ?? this.status,
      seoTitle: seoTitle ?? this.seoTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      isSystem: isSystem ?? this.isSystem,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

/// CMS Blog Category Model
class CmsBlogCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final int sortOrder;
  final DateTime createdAt;

  CmsBlogCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory CmsBlogCategoryModel.fromJson(Map<String, dynamic> json) {
    return CmsBlogCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'name': name.trim(),
      'slug': slug.trim().toLowerCase(),
      'description': description?.trim(),
      'sort_order': sortOrder,
    };
    if (forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}

/// CMS Blog Tag Model
class CmsBlogTagModel {
  final String id;
  final String name;
  final String slug;
  final DateTime createdAt;

  CmsBlogTagModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.createdAt,
  });

  factory CmsBlogTagModel.fromJson(Map<String, dynamic> json) {
    return CmsBlogTagModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'name': name.trim(),
      'slug': slug.trim().toLowerCase(),
    };
    if (forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}

/// CMS Blog Post Model
class CmsBlogPostModel {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String? excerpt;
  final String? featuredImageUrl;
  final String status; // 'draft', 'published'
  final String? categoryId;
  final String? categoryName;
  final List<String> tags;
  final String authorName;
  final String? seoTitle;
  final String? metaDescription;
  final int readTimeMinutes;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  CmsBlogPostModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.excerpt,
    this.featuredImageUrl,
    this.status = 'draft',
    this.categoryId,
    this.categoryName,
    this.tags = const [],
    this.authorName = 'Cosmyra Academic Team',
    this.seoTitle,
    this.metaDescription,
    this.readTimeMinutes = 5,
    this.viewsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';

  factory CmsBlogPostModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
      } else if (json['tags'] is String) {
        parsedTags = (json['tags'] as String)
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll('"', '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    String? catName;
    if (json['cms_blog_categories'] != null && json['cms_blog_categories'] is Map) {
      catName = json['cms_blog_categories']['name']?.toString();
    }

    return CmsBlogPostModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      excerpt: json['excerpt']?.toString(),
      featuredImageUrl: json['featured_image_url']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      categoryId: json['category_id']?.toString(),
      categoryName: catName,
      tags: parsedTags,
      authorName: json['author_name']?.toString() ?? 'Cosmyra Academic Team',
      seoTitle: json['seo_title']?.toString(),
      metaDescription: json['meta_description']?.toString(),
      readTimeMinutes: (json['read_time_minutes'] as num?)?.toInt() ?? 5,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'title': title.trim(),
      'slug': slug.trim().toLowerCase(),
      'content': content,
      'excerpt': excerpt?.trim(),
      'featured_image_url': featuredImageUrl?.trim(),
      'status': status,
      'category_id': categoryId != null && categoryId!.isNotEmpty ? categoryId : null,
      'tags': tags,
      'author_name': authorName.trim(),
      'seo_title': seoTitle?.trim(),
      'meta_description': metaDescription?.trim(),
      'read_time_minutes': readTimeMinutes,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    if (status == 'published') {
      map['published_at'] = publishedAt?.toIso8601String() ?? DateTime.now().toIso8601String();
    } else {
      map['published_at'] = null;
    }
    return map;
  }

  CmsBlogPostModel copyWith({
    String? id,
    String? title,
    String? slug,
    String? content,
    String? excerpt,
    String? featuredImageUrl,
    String? status,
    String? categoryId,
    String? categoryName,
    List<String>? tags,
    String? authorName,
    String? seoTitle,
    String? metaDescription,
    int? readTimeMinutes,
    int? viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return CmsBlogPostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      tags: tags ?? this.tags,
      authorName: authorName ?? this.authorName,
      seoTitle: seoTitle ?? this.seoTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

/// CMS Navigation Menu Model
class CmsNavigationMenuModel {
  final String id;
  final String key; // 'header_main', 'footer_main', 'mobile_drawer', 'app_sidebar'
  final String name;
  final String? description;
  final DateTime createdAt;

  CmsNavigationMenuModel({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory CmsNavigationMenuModel.fromJson(Map<String, dynamic> json) {
    return CmsNavigationMenuModel(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'key': key.trim().toLowerCase(),
      'name': name.trim(),
      'description': description?.trim(),
    };
    if (forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}

/// CMS Navigation Item Model
class CmsNavigationItemModel {
  final String id;
  final String menuId;
  final String label;
  final String linkType; // 'page', 'blog', 'custom_url', 'route'
  final String destination;
  final int sortOrder;
  final bool isVisible;
  final bool openInNewTab;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CmsNavigationItemModel({
    required this.id,
    required this.menuId,
    required this.label,
    required this.linkType,
    required this.destination,
    this.sortOrder = 0,
    this.isVisible = true,
    this.openInNewTab = false,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CmsNavigationItemModel.fromJson(Map<String, dynamic> json) {
    return CmsNavigationItemModel(
      id: json['id']?.toString() ?? '',
      menuId: json['menu_id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      linkType: json['link_type']?.toString() ?? 'custom_url',
      destination: json['destination']?.toString() ?? '/',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isVisible: json['is_visible'] != false,
      openInNewTab: json['open_in_new_tab'] == true,
      parentId: json['parent_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'menu_id': menuId,
      'label': label.trim(),
      'link_type': linkType,
      'destination': destination.trim(),
      'sort_order': sortOrder,
      'is_visible': isVisible,
      'open_in_new_tab': openInNewTab,
      'parent_id': parentId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  CmsNavigationItemModel copyWith({
    String? id,
    String? menuId,
    String? label,
    String? linkType,
    String? destination,
    int? sortOrder,
    bool? isVisible,
    bool? openInNewTab,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CmsNavigationItemModel(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      label: label ?? this.label,
      linkType: linkType ?? this.linkType,
      destination: destination ?? this.destination,
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
      openInNewTab: openInNewTab ?? this.openInNewTab,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
