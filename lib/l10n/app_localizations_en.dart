// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Menu Admin';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Try again';

  @override
  String get refresh => 'Refresh';

  @override
  String get done => 'Done';

  @override
  String get undo => 'Undo';

  @override
  String get search => 'Search';

  @override
  String get more => 'More';

  @override
  String get share => 'Share';

  @override
  String get open => 'Open';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get copiedSecret => 'Copied. It is removed from the clipboard in 1 minute.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get none => 'None';

  @override
  String get all => 'All';

  @override
  String get loading => 'Loading…';

  @override
  String get optional => 'Optional';

  @override
  String get offlineBanner => 'You\'re offline. Showing saved data; changes need a connection.';

  @override
  String updatedAgo(Object time) {
    return 'Updated $time';
  }

  @override
  String savedCopy(Object time) {
    return 'Saved copy · $time';
  }

  @override
  String get errorOffline => 'No connection. Check your internet and try again.';

  @override
  String get errorTimeout => 'The server took too long. Try again.';

  @override
  String get errorServer => 'Something went wrong on the server. Try again in a moment.';

  @override
  String get errorNotFound => 'This was not found. It may have been deleted.';

  @override
  String get errorForbidden => 'You don\'t have permission to do this.';

  @override
  String get errorRateLimited => 'Too many tries. Wait a minute and try again.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get upgradeTitle => 'Upgrade to use this';

  @override
  String get upgradeBody => 'Your plan doesn\'t include this. Upgrade to unlock it.';

  @override
  String get upgradeButton => 'Upgrade';

  @override
  String get upgradeBadge => 'Upgrade';

  @override
  String get readOnlyBanner => 'Your plan has ended. Your menu is read-only until you renew.';

  @override
  String confirmDeleteTitle(Object name) {
    return 'Delete $name?';
  }

  @override
  String get confirmDeleteBody => 'This can\'t be undone.';

  @override
  String get requiredField => 'Required';

  @override
  String get signInTitle => 'Sign in to Menu Admin';

  @override
  String get signInSubtitle => 'For restaurant teams and the platform admin';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get newRestaurant => 'New restaurant? Sign up on the website.';

  @override
  String get privacy => 'Privacy';

  @override
  String get terms => 'Terms';

  @override
  String get twoFactorTitle => 'Two-step sign-in';

  @override
  String get twoFactorBody => 'Enter the 6-digit code from your authenticator app.';

  @override
  String get twoFactorCode => 'Code';

  @override
  String get verify => 'Verify';

  @override
  String get useRecoveryCode => 'Use a recovery code';

  @override
  String get useAuthenticatorCode => 'Use the code from the app';

  @override
  String get recoveryCode => 'Recovery code';

  @override
  String get challengeExpired => 'The sign-in took too long. Please sign in again.';

  @override
  String get serverAddress => 'Server address';

  @override
  String get serverHint => 'e.g. http://192.168.1.20:8000';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody => 'This version of the app is too old. Please update to keep using it.';

  @override
  String get updateNow => 'Update now';

  @override
  String get emailUnverifiedTitle => 'Confirm your e-mail';

  @override
  String emailUnverifiedBody(Object email) {
    return 'We sent a link to $email. Open it to start using your restaurant, then come back.';
  }

  @override
  String get iConfirmed => 'I\'ve confirmed it';

  @override
  String get noRestaurantTitle => 'No restaurant yet';

  @override
  String get noRestaurantBody => 'Your account isn\'t part of a restaurant. Ask the owner for an invitation, or sign up on the website.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutEverywhere => 'Sign out on all devices';

  @override
  String get navHome => 'Home';

  @override
  String get navMenu => 'Menu';

  @override
  String get navSoldOut => 'Sold out';

  @override
  String get navInsights => 'Insights';

  @override
  String get navMore => 'More';

  @override
  String get navRestaurants => 'Restaurants';

  @override
  String get navApprovals => 'Approvals';

  @override
  String get navSearch => 'Search';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String viewingAs(Object name) {
    return 'Viewing as $name';
  }

  @override
  String get backToPlatform => 'Back to platform';

  @override
  String get switchRestaurant => 'Switch restaurant';

  @override
  String get platform => 'Platform';

  @override
  String get openPlatform => 'Open the platform';

  @override
  String dashSoldOut(Object count) {
    return 'Sold out — $count dishes';
  }

  @override
  String get dashSoldOutNone => 'Nothing is sold out';

  @override
  String get manage => 'Manage';

  @override
  String get setupTitle => 'Get your menu ready';

  @override
  String setupProgress(Object done, Object total) {
    return '$done of $total';
  }

  @override
  String get setupHide => 'Hide';

  @override
  String get setup_logo => 'Add your logo';

  @override
  String get setup_banner => 'Add a banner photo';

  @override
  String get setup_dishes => 'Add at least 10 dishes';

  @override
  String get setup_photos => 'Add photos to your dishes';

  @override
  String get setup_hours => 'Set your opening hours';

  @override
  String get setup_info => 'Add your address or phone';

  @override
  String get setup_qr => 'Download or print your QR codes';

  @override
  String get viewsWeek => 'Menu views · 7 days';

  @override
  String get scansWeek => 'QR scans · 7 days';

  @override
  String get viewsToday => 'Views today';

  @override
  String get scansToday => 'Scans today';

  @override
  String vsYesterday(Object count) {
    return 'Yesterday $count';
  }

  @override
  String get viewsChart => 'Menu views';

  @override
  String get last7days => 'Last 7 days';

  @override
  String get missingPhotosTitle => 'Dishes guests look at, without a photo';

  @override
  String missingPhotosMore(Object count) {
    return '$count dishes have no photo';
  }

  @override
  String get myOrderTitle => '“My order” lists';

  @override
  String myOrderShown(Object count) {
    return '$count lists shown · 30 days';
  }

  @override
  String myOrderAverage(Object amount) {
    return 'Average $amount';
  }

  @override
  String get myOrderTop => 'Most added';

  @override
  String get planTitle => 'Plan and usage';

  @override
  String get planTrial => 'Trial';

  @override
  String planEndsIn(Object days) {
    return 'Ends in $days days';
  }

  @override
  String get planEnded => 'Ended';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get usage_items => 'Dishes';

  @override
  String get usage_photos => 'Photos';

  @override
  String get usage_branches => 'Branches';

  @override
  String upgradeTo(Object plan) {
    return 'Upgrade to $plan';
  }

  @override
  String get newsTitle => 'News from the platform';

  @override
  String get openMyMenu => 'Open my menu';

  @override
  String get menuLink => 'Your menu link';

  @override
  String get shareMenu => 'Share menu link';

  @override
  String get copyLink => 'Copy link';

  @override
  String get showQr => 'QR code';

  @override
  String get menus => 'Menus';

  @override
  String get newMenu => 'New menu';

  @override
  String get menuName => 'Menu name';

  @override
  String get renameMenu => 'Rename menu';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get hiddenFromGuests => 'Hidden from guests';

  @override
  String get showToGuests => 'Show to guests';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get schedule => 'Schedule';

  @override
  String get scheduleAlways => 'All day, every day';

  @override
  String get scheduleTimes => 'At set times';

  @override
  String get weekdays => 'Weekdays';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get addTime => 'Add a time';

  @override
  String get branchesShown => 'Branches';

  @override
  String get allBranches => 'All branches';

  @override
  String get categories => 'Categories';

  @override
  String get newCategory => 'New category';

  @override
  String get categoryName => 'Category name';

  @override
  String get renameCategory => 'Rename category';

  @override
  String get noCategories => 'No categories yet';

  @override
  String get noCategoriesBody => 'Add a category such as “Coffee” or “Breakfast”, then add dishes to it.';

  @override
  String get noDishes => 'No dishes in this category';

  @override
  String get addDish => 'Add dish';

  @override
  String get dish => 'Dish';

  @override
  String get dishes => 'Dishes';

  @override
  String get reorder => 'Reorder';

  @override
  String get reorderDone => 'Done reordering';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get available => 'Available';

  @override
  String get soldOut => 'Sold out';

  @override
  String get soldOutSince => 'Sold out';

  @override
  String get availableAgain => 'Available again';

  @override
  String get markSoldOut => 'Sold out';

  @override
  String get guestsSeeSoon => 'Saved. Guests see it within seconds.';

  @override
  String priceFrom(Object price) {
    return 'from $price';
  }

  @override
  String get allDishes => 'All dishes';

  @override
  String get noMenus => 'No menus yet';

  @override
  String get noMenusBody => 'Create your first menu, then add categories and dishes.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get choosePhoto => 'Choose from gallery';

  @override
  String get cropPhoto => 'Crop photo';

  @override
  String get photos => 'Photos';

  @override
  String photosCount(Object count, Object max) {
    return '$count of $max photos';
  }

  @override
  String get mainPhoto => 'Main';

  @override
  String get makeMain => 'Make main photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get uploading => 'Uploading…';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get newDish => 'New dish';

  @override
  String get editDish => 'Edit dish';

  @override
  String get name => 'Name';

  @override
  String get shortDescription => 'Short description';

  @override
  String get description => 'Description';

  @override
  String get price => 'Price';

  @override
  String get sizes => 'Sizes';

  @override
  String get addSize => 'Add size';

  @override
  String get sizeName => 'Size';

  @override
  String get usesSizes => 'Different sizes or prices';

  @override
  String get category => 'Category';

  @override
  String get addons => 'Add-ons';

  @override
  String get tags => 'Tags';

  @override
  String get allergens => 'Allergens';

  @override
  String get calories => 'Calories (kcal)';

  @override
  String get prepMinutes => 'Preparation (minutes)';

  @override
  String get showPhoto => 'Show photo on menu';

  @override
  String get showPhotoHint => 'Off: the menu shows this dish without a photo.';

  @override
  String get visible => 'Visible to guests';

  @override
  String get markNew => 'Mark as new';

  @override
  String get markPopular => 'Mark as popular';

  @override
  String get dishSaved => 'Dish saved';

  @override
  String get deleteDish => 'Delete dish';

  @override
  String get unsavedTitle => 'Discard changes?';

  @override
  String get unsavedBody => 'Your changes to this dish are not saved.';

  @override
  String get discard => 'Discard';

  @override
  String get pricesLocked => 'You can\'t change prices. Ask the owner.';

  @override
  String get allergen_gluten => 'Gluten';

  @override
  String get allergen_crustaceans => 'Crustaceans';

  @override
  String get allergen_eggs => 'Eggs';

  @override
  String get allergen_fish => 'Fish';

  @override
  String get allergen_peanuts => 'Peanuts';

  @override
  String get allergen_soy => 'Soy';

  @override
  String get allergen_milk => 'Milk';

  @override
  String get allergen_nuts => 'Nuts';

  @override
  String get allergen_celery => 'Celery';

  @override
  String get allergen_mustard => 'Mustard';

  @override
  String get allergen_sesame => 'Sesame';

  @override
  String get allergen_sulphites => 'Sulphites';

  @override
  String get allergen_lupin => 'Lupin';

  @override
  String get allergen_molluscs => 'Molluscs';

  @override
  String get tag_vegan => 'Vegan';

  @override
  String get tag_vegetarian => 'Vegetarian';

  @override
  String get tag_spicy => 'Spicy';

  @override
  String get tag_halal => 'Halal';

  @override
  String get tag_gluten_free => 'Gluten-free';

  @override
  String get tag_new => 'New';

  @override
  String get tag_popular => 'Popular';

  @override
  String get soldOutTab => 'Sold out';

  @override
  String get allDishesTab => 'All dishes';

  @override
  String get soldOutEmpty => 'Nothing is sold out';

  @override
  String get soldOutEmptyBody => 'Tap “Sold out” on a dish when it runs out. Guests see it within seconds.';

  @override
  String get soldOutBranchNote => 'Sold out for every branch. For one branch only, use Branches › Prices and availability.';

  @override
  String get filterAll => 'All';

  @override
  String get filterSoldOut => 'Sold out';

  @override
  String get filterHidden => 'Hidden';

  @override
  String get filterNoPhoto => 'No photo';

  @override
  String get filterNew => 'New';

  @override
  String get filterPopular => 'Popular';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get bulkSoldOut => 'Mark sold out';

  @override
  String get bulkAvailable => 'Mark available';

  @override
  String get bulkHide => 'Hide';

  @override
  String get bulkShow => 'Show';

  @override
  String get bulkMove => 'Move to…';

  @override
  String get bulkPrice => 'Change prices';

  @override
  String get bulkDelete => 'Delete';

  @override
  String bulkDeleteTitle(Object count) {
    return 'Delete $count dishes?';
  }

  @override
  String get bulkPriceTitle => 'Change prices';

  @override
  String get bulkPricePercent => 'Change by (%)';

  @override
  String get bulkPriceHint => 'e.g. 10 for +10 %, -5 for −5 %';

  @override
  String get bulkPriceRound => 'Round to';

  @override
  String get noRounding => 'No rounding';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get selectAll => 'Select all';

  @override
  String get sortBy => 'Sort';

  @override
  String get sortCategory => 'Menu order';

  @override
  String get sortName => 'Name';

  @override
  String get sortPrice => 'Price';

  @override
  String get sortUpdated => 'Last changed';

  @override
  String get noMatches => 'Nothing matches';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get branches => 'Branches';

  @override
  String get newBranch => 'New branch';

  @override
  String get branchName => 'Branch name';

  @override
  String get address => 'Address';

  @override
  String get phone => 'Phone';

  @override
  String get mapsLink => 'Map link (https)';

  @override
  String get mainBranch => 'Main branch';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get tables => 'Tables';

  @override
  String tablesCount(Object count) {
    return '$count tables';
  }

  @override
  String get addTables => 'Add tables';

  @override
  String get tableLabel => 'Table name';

  @override
  String get tablesFrom => 'From number';

  @override
  String get tablesTo => 'To number';

  @override
  String get tablesPrefix => 'Prefix (optional)';

  @override
  String get tableCardsPdf => 'Print table cards (PDF)';

  @override
  String get pricesAvailability => 'Prices and availability';

  @override
  String get branchPrice => 'Price here';

  @override
  String get samePrice => 'Same as menu';

  @override
  String get hiddenHere => 'Hidden here';

  @override
  String get soldOutHere => 'Sold out here';

  @override
  String get openBranchPage => 'Open this branch\'s menu';

  @override
  String get qrCodes => 'QR codes';

  @override
  String get printMaterials => 'Print materials';

  @override
  String get qrRestaurant => 'Whole restaurant';

  @override
  String get qrBranch => 'Branch';

  @override
  String get qrTable => 'Table';

  @override
  String get qrExtra => 'Extra code';

  @override
  String get newQr => 'New QR code';

  @override
  String get qrLabel => 'Name (e.g. “Window”)';

  @override
  String get downloadPng => 'Share PNG';

  @override
  String get downloadSvg => 'Share SVG';

  @override
  String get downloadPdf => 'Open PDF';

  @override
  String get printPdf => 'Make PDF';

  @override
  String get material => 'Material';

  @override
  String get design => 'Design';

  @override
  String get darkPrint => 'Dark';

  @override
  String get headline => 'Headline';

  @override
  String get bleed => 'Add 3 mm bleed for a print shop';

  @override
  String get chooseCodes => 'QR codes';

  @override
  String get material_tent => 'Table tent';

  @override
  String get material_poster_a5 => 'Poster A5';

  @override
  String get material_poster_a4 => 'Poster A4';

  @override
  String get material_window => 'Window sign';

  @override
  String get material_sticker_round => 'Round stickers';

  @override
  String get material_sticker_square => 'Square stickers';

  @override
  String get design_classic => 'Classic';

  @override
  String get design_bold => 'Bold';

  @override
  String get design_minimal => 'Minimal';

  @override
  String get socialImages => 'Social media pictures';

  @override
  String get socialPost => 'Post 1080 × 1080';

  @override
  String get socialStory => 'Story 1080 × 1920';

  @override
  String get menuPdf => 'Printable menu (PDF)';

  @override
  String get appearance => 'Appearance';

  @override
  String get menuStyle => 'Menu style';

  @override
  String get style_editorial => 'A · Editorial';

  @override
  String get style_grid => 'B · Grid';

  @override
  String get style_bistro => 'C · Bistro';

  @override
  String get style_minimal => 'D · Minimal';

  @override
  String get brandColour => 'Brand colour';

  @override
  String get font => 'Font';

  @override
  String get font_system => 'Clean (system)';

  @override
  String get font_serif => 'Classic (serif)';

  @override
  String get font_rounded => 'Friendly (rounded)';

  @override
  String get logo => 'Logo';

  @override
  String get banner => 'Banner';

  @override
  String get bannerText => 'Name on the banner';

  @override
  String get bannerOver => 'Over the photo';

  @override
  String get bannerUnder => 'Under the photo';

  @override
  String get bannerNone => 'Logo and name only';

  @override
  String get change => 'Change';

  @override
  String get remove => 'Remove';

  @override
  String get showOnMenu => 'Show on the menu';

  @override
  String get show_prices => 'Prices';

  @override
  String get show_photos => 'Photos';

  @override
  String get show_descriptions => 'Descriptions';

  @override
  String get show_calories => 'Calories';

  @override
  String get show_logo => 'Logo';

  @override
  String get show_banner => 'Banner';

  @override
  String get show_share => 'Share button';

  @override
  String get show_pdf_link => '“Download menu (PDF)” link';

  @override
  String get show_order_list => '“My order” list';

  @override
  String get show_other_branches => 'Other branches in the footer';

  @override
  String get preview => 'Preview';

  @override
  String get livePreview => 'Live preview';

  @override
  String get contrastWarning => 'This colour is light; we darken it a little on the menu so text stays readable.';

  @override
  String get themes => 'Themes';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get infoHours => 'Info and hours';

  @override
  String get about => 'About';

  @override
  String get contact => 'Contact';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get telegram => 'Telegram';

  @override
  String get socials => 'Social links';

  @override
  String get wifi => 'Wi-Fi';

  @override
  String get wifiName => 'Network name';

  @override
  String get wifiPassword => 'Password';

  @override
  String get showWifi => 'Show Wi-Fi on the menu';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get closed => 'Closed';

  @override
  String get addBreak => 'Add hours';

  @override
  String get copyMonday => 'Copy Monday to Tue–Fri';

  @override
  String get holidays => 'Holidays and closures';

  @override
  String get addClosure => 'Add closure';

  @override
  String get note => 'Note';

  @override
  String get startsOn => 'From';

  @override
  String get endsOn => 'Until';

  @override
  String get nextDay => 'next day';

  @override
  String get forBranch => 'For';

  @override
  String get promotions => 'Promotions';

  @override
  String get special => 'Special';

  @override
  String get announcement => 'Announcement';

  @override
  String get newSpecial => 'New special';

  @override
  String get newAnnouncement => 'New announcement';

  @override
  String get title => 'Title';

  @override
  String get text => 'Text';

  @override
  String get linkedDish => 'Linked dish';

  @override
  String get startsAt => 'Starts';

  @override
  String get endsAt => 'Ends';

  @override
  String get noEnd => 'No end';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get happyHour => 'Happy hour';

  @override
  String get pricePeriods => 'Time-based prices';

  @override
  String get newPricePeriod => 'New price period';

  @override
  String get periodName => 'Name shown to guests';

  @override
  String get fixedPrice => 'New price';

  @override
  String get percentOff => '% off';

  @override
  String get value => 'Value';

  @override
  String get allDay => 'All day';

  @override
  String get addDishes => 'Add dishes';

  @override
  String get insights => 'Insights';

  @override
  String get days7 => '7 days';

  @override
  String get days30 => '30 days';

  @override
  String get days90 => '90 days';

  @override
  String get menuViews => 'Menu views';

  @override
  String get qrScans => 'QR scans';

  @override
  String get dishViews => 'Dish views';

  @override
  String get topDishes => 'Most viewed dishes';

  @override
  String get scansPerCode => 'Scans per QR code';

  @override
  String get export => 'Export';

  @override
  String get exportViews => 'Views and scans per day (CSV)';

  @override
  String get exportQr => 'Scans per QR code (CSV)';

  @override
  String get exportDishes => 'Dishes (CSV)';

  @override
  String get exportPdf => 'Report (PDF)';

  @override
  String get monthlyReport => 'Monthly report by e-mail';

  @override
  String get monthlyReportHint => 'On the 1st, owners get last month\'s report.';

  @override
  String get deletedCode => 'Deleted code';

  @override
  String get team => 'Team';

  @override
  String get invite => 'Invite';

  @override
  String get inviteTitle => 'Invite to your team';

  @override
  String get role => 'Role';

  @override
  String get role_owner => 'Owner';

  @override
  String get role_manager => 'Manager';

  @override
  String get role_staff => 'Staff';

  @override
  String get canEditPrices => 'Can change prices';

  @override
  String get pendingInvitations => 'Waiting for an answer';

  @override
  String expires(Object date) {
    return 'Expires $date';
  }

  @override
  String get removeMember => 'Remove from team';

  @override
  String get you => 'You';

  @override
  String get inviteSent => 'Invitation sent';

  @override
  String get billing => 'Billing';

  @override
  String get plan => 'Plan';

  @override
  String get paidUntil => 'Paid until';

  @override
  String get trialEnds => 'Trial ends';

  @override
  String get invoices => 'Invoices';

  @override
  String get noInvoices => 'No invoices yet';

  @override
  String get status => 'Status';

  @override
  String get state_trial => 'Trial';

  @override
  String get state_active => 'Active';

  @override
  String get state_grace => 'Grace period';

  @override
  String get state_read_only => 'Read-only';

  @override
  String get state_unavailable => 'Unavailable';

  @override
  String get state_free => 'Free';

  @override
  String get state_pending => 'Pending';

  @override
  String get activity => 'Activity';

  @override
  String get news => 'News';

  @override
  String get restaurantSection => 'Restaurant';

  @override
  String get account => 'Account';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help and support';

  @override
  String get profileTitle => 'Profile';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Repeat new password';

  @override
  String get passwordChanged => 'Password changed. Other devices were signed out.';

  @override
  String get passwordsDontMatch => 'The passwords don\'t match';

  @override
  String get twoFactor => 'Two-step sign-in';

  @override
  String get twoFactorOn => 'On';

  @override
  String get twoFactorOff => 'Off';

  @override
  String get twoFactorTurnOn => 'Turn on';

  @override
  String get twoFactorTurnOff => 'Turn off';

  @override
  String get twoFactorScan => 'Scan this code with an authenticator app (Google Authenticator, Microsoft Authenticator, 1Password…), or enter the key.';

  @override
  String get twoFactorKey => 'Key';

  @override
  String get twoFactorConfirm => 'Enter the 6-digit code to finish';

  @override
  String get recoveryCodes => 'Recovery codes';

  @override
  String get recoveryCodesHint => 'Keep these somewhere safe. Each works once if you lose your phone.';

  @override
  String get newRecoveryCodes => 'New recovery codes';

  @override
  String get confirmPasswordTitle => 'Confirm your password';

  @override
  String get devices => 'Devices';

  @override
  String get thisDevice => 'This device';

  @override
  String lastUsed(Object time) {
    return 'Last used $time';
  }

  @override
  String get signOutDevice => 'Sign out this device';

  @override
  String signOutDeviceConfirm(Object name) {
    return 'Sign out $name?';
  }

  @override
  String get emailChangedVerify => 'Check your inbox to confirm the new e-mail.';

  @override
  String get notificationSettings => 'Notifications';

  @override
  String get notificationsGroupRestaurant => 'Restaurant';

  @override
  String get notificationsGroupPlatform => 'Platform';

  @override
  String get pushNotSetUp => 'Push notifications are not set up on this server yet. You\'ll still see notifications in the app.';

  @override
  String get inbox => 'Notifications';

  @override
  String get inboxEmpty => 'No notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get appSettings => 'App settings';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint => 'Ask for your fingerprint, face or PIN when opening the app.';

  @override
  String get autoLock => 'Lock after';

  @override
  String minutes(Object count) {
    return '$count min';
  }

  @override
  String get setPin => 'Set a PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String get pinHint => '4 to 6 digits';

  @override
  String get pinWrong => 'Wrong PIN';

  @override
  String get rootWarning =>
      'This phone looks rooted or jailbroken. The app works, but other apps on it may be able to read your restaurant data. If you can, use a phone that is not modified.';

  @override
  String pinWait(int seconds) {
    return 'Too many wrong PINs. Try again in $seconds s.';
  }

  @override
  String pinTriesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tries left before the app signs out',
      one: '1 try left before the app signs out',
    );
    return '$_temp0';
  }

  @override
  String get pinSignedOut => 'Too many wrong PINs, so the app signed out. Sign in again with your password.';

  @override
  String get unlock => 'Unlock';

  @override
  String get useBiometrics => 'Use fingerprint or face';

  @override
  String get crashReports => 'Send crash reports';

  @override
  String get crashReportsHint => 'When the app crashes, send a technical report (no menu content, no personal data) so we can fix it.';

  @override
  String get usageStats => 'Anonymous usage statistics';

  @override
  String get usageStatsHint => 'Which screens and features are used, to improve the app. Never your menu content.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Follow the system';

  @override
  String version(Object version) {
    return 'Version $version';
  }

  @override
  String get licences => 'Open-source licences';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get supportWhatsapp => 'WhatsApp support';

  @override
  String get supportEmail => 'E-mail support';

  @override
  String get rateApp => 'Rate the app';

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String get upToDate => 'You have the latest version';

  @override
  String get lockedTitle => 'Menu Admin is locked';

  @override
  String get kpiRestaurants => 'Restaurants';

  @override
  String get kpiActive => 'Active (daily avg.)';

  @override
  String get kpiNew => 'New';

  @override
  String get kpiPaying => 'Paying';

  @override
  String get kpiFree => 'Free';

  @override
  String get kpiMrr => 'MRR';

  @override
  String get kpiRevenue => 'Revenue';

  @override
  String get kpiViews => 'Menu views';

  @override
  String get kpiScans => 'QR scans';

  @override
  String vsPrevious(Object change) {
    return '$change vs previous';
  }

  @override
  String get growth => 'Growth';

  @override
  String get healthGroups => 'Restaurant health';

  @override
  String get health_healthy => 'Healthy';

  @override
  String get health_at_risk => 'At risk';

  @override
  String get health_inactive => 'Inactive';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get expiringSoon => 'Ending soon';

  @override
  String get inactiveRestaurants => 'Inactive';

  @override
  String get newSignups => 'New sign-ups';

  @override
  String get systemHealth => 'System health';

  @override
  String get followUpsDue => 'Follow-ups due';

  @override
  String get topRestaurants => 'Top restaurants';

  @override
  String get featureUse => 'Feature use';

  @override
  String get days365 => '1 year';

  @override
  String get restaurants => 'Restaurants';

  @override
  String get owner => 'Owner';

  @override
  String get created => 'Created';

  @override
  String get overview => 'Overview';

  @override
  String get payments => 'Payments';

  @override
  String get features => 'Features';

  @override
  String get notesTags => 'Notes and tags';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get amount => 'Amount';

  @override
  String get method => 'Method';

  @override
  String get method_cash => 'Cash';

  @override
  String get method_bank => 'Bank transfer';

  @override
  String get method_mobile_money => 'Mobile money';

  @override
  String get method_other => 'Other';

  @override
  String get reference => 'Reference';

  @override
  String get paidOn => 'Paid on';

  @override
  String get months => 'Months';

  @override
  String get paymentSaved => 'Payment saved. Invoice created.';

  @override
  String get invoice => 'Invoice';

  @override
  String get resendInvoice => 'E-mail again';

  @override
  String get voidInvoice => 'Void';

  @override
  String voidConfirm(Object number) {
    return 'Void invoice $number?';
  }

  @override
  String get suspend => 'Suspend';

  @override
  String get unsuspend => 'Restore access';

  @override
  String get suspendReason => 'Reason (shown to the owner)';

  @override
  String get deleteRestaurant => 'Delete restaurant';

  @override
  String get restoreRestaurant => 'Restore restaurant';

  @override
  String get deleteRestaurantBody => 'It can be restored for 30 days, then it\'s gone for good.';

  @override
  String get logInAs => 'Log in as owner';

  @override
  String get logInAsBody => 'You\'ll see the admin as the owner for up to 2 hours. Password, e-mail and some other changes stay blocked.';

  @override
  String get trialUntil => 'Trial until';

  @override
  String get changePlan => 'Change plan';

  @override
  String get setTrial => 'Set trial end';

  @override
  String get featureDefault => 'Plan default';

  @override
  String get featureOn => 'On for this restaurant';

  @override
  String get featureOff => 'Off for this restaurant';

  @override
  String get notes => 'Notes';

  @override
  String get addNote => 'Add note';

  @override
  String get followUp => 'Follow-up';

  @override
  String get followUpOn => 'Follow up on';

  @override
  String get followUpReason => 'Why';

  @override
  String get clearFollowUp => 'Clear follow-up';

  @override
  String get menusCount => 'Menus';

  @override
  String get itemsCount => 'Dishes';

  @override
  String get views30 => 'Views (30 days)';

  @override
  String get approvals => 'Approvals';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get rejectReason => 'Reason for the owner';

  @override
  String get approvalsEmpty => 'No sign-ups waiting';

  @override
  String get plans => 'Plans';

  @override
  String get planName => 'Plan name';

  @override
  String get priceMonth => 'Price per month';

  @override
  String get priceYear => 'Price per year';

  @override
  String get trialDays => 'Trial days';

  @override
  String get limits => 'Limits';

  @override
  String get limit_photos => 'Photos';

  @override
  String get limit_branches => 'Branches';

  @override
  String get limit_menus => 'Menus';

  @override
  String get limit_items => 'Dishes';

  @override
  String get limit_tables => 'Tables';

  @override
  String get limit_members => 'Team members';

  @override
  String get limit_languages => 'Languages';

  @override
  String get publicPlan => 'Shown on the website';

  @override
  String restaurantsOnPlan(Object count) {
    return '$count restaurants';
  }

  @override
  String get invoicesTitle => 'Invoices';

  @override
  String get paymentsTitle => 'Payments';

  @override
  String get messages => 'Messages';

  @override
  String get newMessage => 'New e-mail';

  @override
  String get subject => 'Subject';

  @override
  String get message => 'Message';

  @override
  String get recipients => 'Recipients';

  @override
  String recipientsCount(Object count) {
    return '$count restaurant owners';
  }

  @override
  String get filterPlan => 'Plan';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterTag => 'Tag';

  @override
  String get filterInactiveDays => 'Inactive for (days)';

  @override
  String get status_active => 'Paying';

  @override
  String get status_trial => 'Trial';

  @override
  String get status_expiring => 'Ending soon';

  @override
  String get status_expired => 'Ended';

  @override
  String get status_suspended => 'Suspended';

  @override
  String get sendTest => 'Send me a test';

  @override
  String get testSent => 'Test sent';

  @override
  String get sendNow => 'Send';

  @override
  String sendConfirm(Object count) {
    return 'Send to $count owners?';
  }

  @override
  String get campaignSent => 'Sending started';

  @override
  String get sent => 'Sent';

  @override
  String get failed => 'Failed';

  @override
  String get waiting => 'Waiting';

  @override
  String get retryFailed => 'Resend to failed';

  @override
  String get placeholdersHint => 'Placeholders in curly brackets: restaurant_name, owner_name, plan, menu_link.';

  @override
  String get backups => 'Backups';

  @override
  String get backUpNow => 'Back up now';

  @override
  String get backupQueued => 'Backup started';

  @override
  String get backupDownloadsWeb => 'Downloads are on the web admin only, for safety.';

  @override
  String diskFree(Object free, Object total) {
    return '$free free of $total';
  }

  @override
  String get backupProblem => 'Problem';

  @override
  String get offsite => 'Off-site';

  @override
  String get globalSearch => 'Search restaurants, owners, invoices…';

  @override
  String get group_restaurants => 'Restaurants';

  @override
  String get group_owners => 'Owners';

  @override
  String get group_invoices => 'Invoices';

  @override
  String get group_payments => 'Payments';

  @override
  String get group_tags => 'Tags';

  @override
  String get searchMin => 'Type at least 2 letters';

  @override
  String get announcements => 'Announcements';

  @override
  String get newAnnouncementTitle => 'New announcement';

  @override
  String get level => 'Level';

  @override
  String get level_info => 'Info';

  @override
  String get level_warning => 'Warning';

  @override
  String get allPlans => 'All plans';

  @override
  String get platformSettings => 'Settings';

  @override
  String get tab_general => 'General';

  @override
  String get tab_signup => 'Sign-up';

  @override
  String get tab_landing => 'Landing page';

  @override
  String get tab_billing => 'Billing';

  @override
  String get tab_legal => 'Terms and privacy';

  @override
  String get tab_images => 'Logo and link preview';

  @override
  String get tab_mail => 'E-mail (SMTP)';

  @override
  String get tab_app => 'Mobile app';

  @override
  String get resetDefault => 'Reset to default text';

  @override
  String get smtpHost => 'Host';

  @override
  String get smtpPort => 'Port';

  @override
  String get smtpEncryption => 'Encryption';

  @override
  String get smtpUsername => 'Username';

  @override
  String get smtpPassword => 'Password';

  @override
  String get smtpFromAddress => 'From address';

  @override
  String get smtpFromName => 'From name';

  @override
  String get sendTestTo => 'Send a test e-mail to';

  @override
  String get uploadImage => 'Upload';

  @override
  String get appMinVersion => 'Minimum app version';

  @override
  String get appLatestVersion => 'Latest app version';

  @override
  String get appFlags => 'Feature flags';

  @override
  String get addFlag => 'Add flag';

  @override
  String get flagName => 'Flag name';

  @override
  String get platformActivity => 'Activity log';

  @override
  String get logInAsStarted => 'Now viewing as the owner';

  @override
  String get resendWelcome => 'Send the welcome e-mail again';
}
