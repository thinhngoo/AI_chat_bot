import '../../../core/utils/format_utils.dart' as core_format;

/// Utility class cho các phương thức định dạng dùng cho knowledge base
class KnowledgeBaseFormatter {
  // Phòng ngừa khởi tạo
  KnowledgeBaseFormatter._();

  /// Định dạng bytes thành chuỗi đọc được
  static String formatBytes(int? bytes) {
    // Sử dụng hàm formatBytes từ core utils
    return core_format.formatBytes(bytes);
  }

  /// Định dạng số đơn vị thành chuỗi
  static String formatUnits(int count) {
    return '$count ${count == 1 ? 'unit' : 'units'}';
  }
}
