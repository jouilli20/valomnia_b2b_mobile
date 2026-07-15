class ApiConstants {
  ApiConstants._();

  /// Base URL
  static const String baseUrl = 'https://api.valomnia.com/api/';

  /// Tenant Base URL
  static const String tenantBaseUrl = 'https://agro.valomnia.com';

  /// Web orders URL used by checkout confirmation emails.
  static const String webOrdersUrl = 'https://shop.valomnia.com/orders';

  /// Fallback organization logo used by checkout confirmation emails.
  static const String organizationLogoUrl =
      'https://agro.valomnia.com/uploads/agro-1706801472256/photoOrganization/1709559844806_food_industry_icon_2.png';

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
