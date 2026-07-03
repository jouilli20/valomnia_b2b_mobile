class ApiConstants {
  ApiConstants._();

  /// Base URL
  static const String baseUrl = 'https://api.valomnia.com/api/';

  /// Tenant Base URL
  static const String tenantBaseUrl = 'https://api.valomnia.com/api/';

  /// Headers
  static const String jsonContentType = 'application/json';
  static const String formUrlEncodedContentType =
      'application/x-www-form-urlencoded';

  // ==========================
  // Authentication
  // ==========================

  static const String login = 'loginB2B';
  static const String checkPassword = 'check-password';
  static const String updateUser = 'update-user';
  static const String userCheck = 'user/check';
  static const String forgotPassword = 'forgot-password';
  static const String resetPassword = 'reset-password';

  // ==========================
  // Catalog
  // ==========================

  static const String items = 'items';
  static const String itemCategories = 'itemCategories';
  static const String prices = 'prices';
  static const String item = 'item';

  // ==========================
  // Customer
  // ==========================

  static const String customer = 'customer';
  static const String customerMinOrderTotal = 'customerMinOrderTotal';

  // ==========================
  // Orders
  // ==========================

  static const String orders = 'orders';
  static const String addOrder = 'add-order';
  static const String checkoutEmail = 'checkoutEmail';

  // ==========================
  // System
  // ==========================

  static const String health = 'user';
}