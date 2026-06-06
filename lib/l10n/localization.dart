import "package:delforte/l10n/portuguese.dart";

/// The active translation. Swap this to change the app language.
Localization strings = Portuguese();

/// All user-facing strings in the app.
///
/// Implement this for each supported language and assign an instance to
/// [strings] to translate the whole UI. Getters return plain strings;
/// methods compose strings that include runtime values.
abstract class Localization {
  // Common
  late final String appName;
  late final String continueLabel;
  late final String back;
  late final String ok;
  late final String cancel;
  late final String delete;
  late final String total;
  late final String unit;
  late final String description;
  late final String address;
  late final String addressHint;
  late final String phone;
  late final String email;

  // Home
  late final String newQuote;
  late final String newQuoteSubtitle;
  late final String recentQuotes;
  late final String seeAll;
  late final String noQuotesYet;
  late final String noQuotesYetSubtitle;
  late final String resumeDraftSubtitle;
  late final String templatesSubtitle;
  late final String catalogSubtitle;
  late final String statusDraft;
  late final String statusSaved;
  late final String unknownClient;

  // Quotes list
  late final String quotes;
  late final String noQuotesFound;
  late final String noQuotesFoundSubtitle;

  // Client select
  late final String selectClient;
  late final String createNewClient;

  // Client create
  late final String newClient;
  late final String sectionContact;
  late final String fullName;
  late final String fullNameHint;
  late final String phoneHint;
  late final String emailHint;
  late final String sectionLocation;
  late final String city;
  late final String cityHint;
  late final String saveClient;
  late final String clientNameRequired;

  late final String search;
  late final String searchAdd;

  // Services
  late final String services;
  late final String servicesTotal;
  late final String createNewService;

  // Service create
  late final String newService;
  late final String sectionIdentity;
  late final String serviceName;
  late final String serviceNameHint;
  late final String serviceDescriptionHint;
  late final String sectionPricing;
  late final String defaultPrice;
  late final String priceHint;
  late final String saveService;
  late final String serviceNameRequired;

  // Equipment
  late final String equipment;
  late final String equipmentTotal;
  late final String createNewEquipment;

  // Catalog
  late final String catalog;
  late final String catalogNew;
  late final String saveChanges;
  late final String changesSaved;
  late final String noServicesYet;
  late final String noEquipmentYet;
  late final String catalogEmptySubtitle;

  // Clients manager
  late final String clients;
  late final String clientsSubtitle;
  late final String noClientsYet;
  late final String clientsEmptySubtitle;

  // Equipment create
  late final String newEquipment;
  late final String sectionProduct;
  late final String equipmentName;
  late final String equipmentNameHint;
  late final String equipmentDescriptionHint;
  late final String unitPrice;
  late final String saveEquipment;
  late final String equipmentNameRequired;

  // Review
  late final String review;
  late final String looksGood;
  late final String client;
  late final String noClientSelected;
  late final String returnToClientStep;
  late final String editClient;

  // Send
  late final String send;
  late final String sendQuote;
  late final String quoteReady;
  late final String shareWhatsApp;
  late final String sharingNotWired;
  late final String exportPdf;
  late final String copyLink;
  late final String copyLinkUnavailable;
  late final String backToHome;

  // PDF preview
  late final String pdfPreview;
  late final String share;

  // PDF document
  late final String pdfQuote;
  late final String pdfBillTo;
  late final String pdfPayment;
  late final String pdfQty;
  late final String pdfPrice;
  late final String pdfSubtotal;
  late final String pdfDefaultValidity;
  late final String pdfDefaultWarranty;
  late final String pdfDefaultTerms;
  late final List<String> monthAbbreviations;

  // Settings
  late final String settings;
  late final String sectionBusiness;
  late final String businessName;
  late final String businessNameHint;
  late final String cnpj;
  late final String cnpjHint;
  late final String cityState;
  late final String cityStateHint;
  late final String businessPhoneHint;
  late final String businessEmailHint;
  late final String sectionQuoteDefaults;
  late final String paymentMethod;
  late final String paymentMethodHint;
  late final String quoteValidity;
  late final String quoteValidityHint;
  late final String warranty;
  late final String warrantyHint;
  late final String termsConditions;
  late final String termsHint;
  late final String sectionPdfFooterPreview;
  late final String footerPreviewNote;
  late final String save;
  late final String discardChangesTitle;
  late final String discardChangesMessage;
  late final String discard;
  late final String companyLogo;
  late final String companyLogoNote;
  late final String change;
  late final String showLogoOnPdf;
  late final String includeQrCode;
  late final String includeQrCodeNote;
  late final String showItemCostPrice;
  late final String showItemCostPriceNote;

  // Templates
  late final String templates;
  late final String pageUnavailable;
  late final String templatesDisabledMessage;
  late final String templatesEmptySubtitle;

  // Widgets
  late final String increase;
  late final String decrease;
  late final String selectUnit;
  late final String noUnits;
  late final String noLinesAdded;

  // App bootstrap
  late final String databaseOpenError;
  late final String tryAgain;

  // Composed strings (include runtime values)
  String quoteMeta(int services, int equipment);
  String servicesChip(int count);
  String equipmentChip(int count);
  String savedLocally(String clientName, String total);
  String validFor(String validity);
  String cnpjLabel(String cnpj);
  String editGroup(String title);
  String deleteCatalogItemConfirm(String name);
  String pdfGeneratedBy(String business, String code, String date);
}
