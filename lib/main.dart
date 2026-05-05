import "dart:async";

import "package:delforte/design_system.dart";
import "package:delforte/design_system/widgets/flow_header_widget.dart";
import "package:delforte/store.dart";
import "package:flutter/material.dart";

void main() {
  runApp(const MainApp());
}

enum AppScreen { home, clients, services, items, review, send, quotes, templates }

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Delforte",
      theme: VigilTheme.light(),
      home: const QuoteHome(),
    );
  }
}

class QuoteHome extends StatefulWidget {
  const QuoteHome({super.key});

  @override
  State<QuoteHome> createState() => _QuoteHomeState();
}

class _QuoteHomeState extends State<QuoteHome> {
  final QuoteStore _store = QuoteStore();
  final TextEditingController _clientSearch = TextEditingController();
  final TextEditingController _serviceSearch = TextEditingController();
  final TextEditingController _itemSearch = TextEditingController();
  final TextEditingController _quoteSearch = TextEditingController();
  final TextEditingController _templateSearch = TextEditingController();

  AppScreen _screen = AppScreen.home;
  bool _opening = true;
  bool _opened = false;
  int? _selectedClientId;
  int? _expandedServiceId;
  int? _expandedItemId;
  int? _savedTotalCents;
  bool _quoteSaved = false;

  @override
  void initState() {
    super.initState();
    unawaited(_openStore());
  }

  Future<void> _openStore() async {
    final bool opened = await _store.open();
    if (opened) _seedEmptyStore();
    if (!mounted) return;
    setState(() {
      _opened = opened;
      _opening = false;
    });
  }

  void _seedEmptyStore() {
    if (_store.clients.count == 0) {
      _store.addClient("Residencial Oliveira", "(11) 98888-1010", "", "Rua das Flores, 142");
      _store.addClient("Comercio Santos", "(11) 97777-2020", "", "Av. Central, 88 - Bloco B");
      _store.addClient("Casa Joao Silva", "(11) 96666-3030", "", "Estrada do Morro, 55");
    }
    if (_store.services.count == 0) {
      _store.addService("CCTV Installation", "Camera installation and setup", 60000);
      _store.addService("Alarm System Setup", "Panel, sensors, and configuration", 40000);
      _store.addService("Gate Motor Install", "Gate motor installation labor", 20000);
    }
    if (_store.items.count == 0) {
      _store.addItem("IP Camera 4MP", "Outdoor infrared camera", 35000);
      _store.addItem("Gate Motor Kit", "Motor, remotes, and rails", 85000);
      _store.addItem("Control Panel Pro", "Alarm and automation control panel", 95000);
    }
  }

  @override
  void dispose() {
    _clientSearch.dispose();
    _serviceSearch.dispose();
    _itemSearch.dispose();
    _quoteSearch.dispose();
    _templateSearch.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _store.clientsNotifier,
        _store.itemsNotifier,
        _store.servicesNotifier,
        _store.quotesNotifier,
        _store.quoteDraftNotifier,
        _store.errorsNotifier,
      ]),
      builder: (context, _) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: VigilGradients.appBackdrop),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ClipRRect(
                    borderRadius: VigilRadius.appFrameRadius,
                    child: ColoredBox(color: VigilColors.canvas, child: _buildBody()),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_opening) {
      return const SizedBox.expand(child: Center(child: CircularProgressIndicator()));
    }
    if (!_opened) {
      return _ErrorState(
        message: _store.latestErrorMessage().isEmpty
            ? "Could not open the quote database."
            : _store.latestErrorMessage(),
        onRetry: () async {
          setState(() => _opening = true);
          await _openStore();
        },
      );
    }

    return switch (_screen) {
      AppScreen.home => _homeScreen(),
      AppScreen.clients => _clientScreen(),
      AppScreen.services => _catalogScreen(type: quoteLineService),
      AppScreen.items => _catalogScreen(type: quoteLineItem),
      AppScreen.review => _reviewScreen(),
      AppScreen.send => _sendScreen(),
      AppScreen.quotes => _quotesScreen(),
      AppScreen.templates => _templatesScreen(),
    };
  }

  Widget _homeScreen() {
    return Column(
      children: [
        const _BrandHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            children: [
              Transform.translate(
                offset: const Offset(0, -16),
                child: _NewQuoteCard(
                  onTap: () {
                    _store.clearDraft();
                    setState(() {
                      _selectedClientId = null;
                      _quoteSaved = false;
                      _savedTotalCents = null;
                      _screen = AppScreen.clients;
                    });
                  },
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -6),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        label: "Continue",
                        subtitle: "Resume a draft",
                        icon: Icons.edit_note_rounded,
                        onTap: () => setState(() => _screen = AppScreen.clients),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        label: "Templates",
                        subtitle: "Start from preset",
                        icon: Icons.layers_rounded,
                        onTap: () => setState(() => _screen = AppScreen.templates),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionTitle(
                title: "Recent Quotes",
                action: "See all",
                onAction: () => setState(() => _screen = AppScreen.quotes),
              ),
              const SizedBox(height: 12),
              if (_store.quotes.count == 0)
                const _EmptyPanel(
                  icon: Icons.receipt_long_rounded,
                  title: "No saved quotes yet",
                  subtitle: "Create a quote and save it from the review flow.",
                )
              else
                for (var i = 0; i < _store.quotes.count && i < 3; i++)
                  _QuoteCard(
                    clientName: _clientNameById(_store.quotes.clientIdAt(i)),
                    meta: _dateLabel(_store.quotes.timestampAt(i)),
                    total: _formatMoney(_store.quotes.totalCentsAt(i)),
                    status: "Saved",
                    statusColor: VigilColors.success,
                    statusBg: VigilColors.successSoft,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _clientScreen() {
    final String query = _clientSearch.text.trim().toLowerCase();
    final List<int> indexes = [
      for (var i = 0; i < _store.clients.count; i++)
        if (query.isEmpty ||
            _store.clients.nameAt(i).toLowerCase().contains(query) ||
            _store.clients.addressAt(i).toLowerCase().contains(query))
          i,
    ];

    return Column(
      children: [
        FlowHeader(
          title: "Select Client",
          stepIndex: 0,
          onBack: () => setState(() => _screen = AppScreen.home),
          onContinue: _selectedClientId == null
              ? null
              : () => setState(() => _screen = AppScreen.services),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: _clientSearch,
                hintText: "Search clients...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              for (final int index in indexes) _clientCard(index),
              _AddCard(label: "Add new client", onTap: _showClientDialog),
            ],
          ),
        ),
      ],
    );
  }

  Widget _clientCard(int index) {
    final int id = _store.clients.idAt(index);
    final bool selected = _selectedClientId == id;
    final String name = _store.clients.nameAt(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? VigilColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedClientId = id),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: selected ? VigilColors.primary : VigilColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  _InitialsAvatar(text: _initials(name), selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _bodyStyle(weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          _store.clients.addressAt(index),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _smallStyle(color: VigilColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (selected) const Icon(Icons.check_circle_rounded, color: VigilColors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catalogScreen({required int type}) {
    final bool isService = type == quoteLineService;
    final ItemData data = isService ? _store.services : _store.items;
    final TextEditingController controller = isService ? _serviceSearch : _itemSearch;
    final String query = controller.text.trim().toLowerCase();
    final List<int> indexes = [
      for (var i = 0; i < data.count; i++)
        if (query.isEmpty ||
            data.nameAt(i).toLowerCase().contains(query) ||
            data.descriptionAt(i).toLowerCase().contains(query))
          i,
    ];

    return Column(
      children: [
        FlowHeader(
          title: isService ? "Services" : "Equipment",
          stepIndex: isService ? 1 : 2,
          total: isService ? _draftTotalFor(quoteLineService) : _draftTotalFor(quoteLineItem),
          totalLabel: isService ? "Services Total" : "Equipment Total",
          onBack: () =>
              setState(() => _screen = isService ? AppScreen.clients : AppScreen.services),
          onContinue: () =>
              setState(() => _screen = isService ? AppScreen.items : AppScreen.review),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: controller,
                hintText: isService ? "Search to add a service..." : "Search to add equipment...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              for (final int index in indexes)
                _CatalogCard(
                  name: data.nameAt(index),
                  description: data.descriptionAt(index),
                  price: _formatMoney(data.priceCentsAt(index)),
                  icon: _catalogIcon(data.nameAt(index), isService: isService),
                  expanded: (isService ? _expandedServiceId : _expandedItemId) == data.idAt(index),
                  selectedQuantity: _draftQuantity(type, data.idAt(index)),
                  onToggle: () => setState(() {
                    final int id = data.idAt(index);
                    if (isService) {
                      _expandedServiceId = _expandedServiceId == id ? null : id;
                    } else {
                      _expandedItemId = _expandedItemId == id ? null : id;
                    }
                  }),
                  onAdd: () => _addDraftLine(type, data.idAt(index)),
                  onDecrease: () => _changeDraftQuantity(type, data.idAt(index), -1),
                  onIncrease: () => _changeDraftQuantity(type, data.idAt(index), 1),
                  onRemove: () => _removeDraftLine(type, data.idAt(index)),
                ),
              _AddCard(
                label: isService ? "Add new service" : "Add new equipment",
                onTap: () => _showCatalogDialog(isService: isService),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewScreen() {
    final int total = _store.draft.computeTotals();
    final int? clientId = _selectedClientId;
    final int clientIndex = clientId == null ? -1 : _store.clients.indexOfId(clientId);

    return Column(
      children: [
        FlowHeader(
          title: "Review",
          stepIndex: 3,
          continueLabel: "Looks Good",
          onBack: () => setState(() => _screen = AppScreen.items),
          onContinue: _canSaveQuote ? _saveAndContinue : null,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Panel(
                title: "Client",
                child: Row(
                  children: [
                    _InitialsAvatar(
                      text: clientIndex >= 0 ? _initials(_store.clients.nameAt(clientIndex)) : "--",
                      selected: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientIndex >= 0
                                ? _store.clients.nameAt(clientIndex)
                                : "No client selected",
                            style: _bodyStyle(weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            clientIndex >= 0
                                ? _store.clients.addressAt(clientIndex)
                                : "Return to client step",
                            style: _smallStyle(color: VigilColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Edit client",
                      onPressed: () => setState(() => _screen = AppScreen.clients),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _LineGroup(
                title: "Services",
                lines: _draftLines(quoteLineService),
                onEdit: () => setState(() => _screen = AppScreen.services),
              ),
              const SizedBox(height: 10),
              _LineGroup(
                title: "Equipment",
                lines: _draftLines(quoteLineItem),
                onEdit: () => setState(() => _screen = AppScreen.items),
              ),
              const SizedBox(height: 10),
              _TotalBanner(label: "Total", amount: _formatMoney(total)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sendScreen() {
    final int total = _savedTotalCents ?? _store.draft.computeTotals();
    final int serviceCount = _draftCountFor(quoteLineService);
    final int itemCount = _draftCountFor(quoteLineItem);
    return Column(
      children: [
        FlowHeader(
          title: "Send Quote",
          stepIndex: 4,
          onBack: () => setState(() => _screen = AppScreen.review),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            children: [
              _ReadyCard(
                title: _quoteSaved ? "Quote Ready" : "Quote Not Saved",
                subtitle: _quoteSaved
                    ? "Saved locally - ${_clientNameById(_selectedClientId ?? 0)} - ${_formatMoney(total)}"
                    : _store.latestErrorMessage(),
                chips: ["$serviceCount services", "$itemCount items", _formatMoney(total)],
              ),
              const SizedBox(height: 10),
              _PrimaryButton(
                label: "Share via WhatsApp",
                icon: Icons.share_rounded,
                onPressed: () => _showSnack("Sharing is not wired yet."),
              ),
              const SizedBox(height: 10),
              _SecondaryButton(
                label: "Export PDF",
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () => _showSnack("PDF export is not wired to the UI yet."),
              ),
              const SizedBox(height: 10),
              _SecondaryButton(
                label: "Copy Link",
                icon: Icons.link_rounded,
                onPressed: () => _showSnack("Link sharing is not available for local drafts."),
              ),
              TextButton(
                onPressed: () {
                  _store.clearDraft();
                  setState(() {
                    _selectedClientId = null;
                    _quoteSaved = false;
                    _savedTotalCents = null;
                    _screen = AppScreen.home;
                  });
                },
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quotesScreen() {
    final String query = _quoteSearch.text.trim().toLowerCase();
    final List<int> indexes = [
      for (var i = 0; i < _store.quotes.count; i++)
        if (query.isEmpty ||
            _clientNameById(_store.quotes.clientIdAt(i)).toLowerCase().contains(query))
          i,
    ];

    return Column(
      children: [
        FlowHeader(title: "Quotes", onBack: () => setState(() => _screen = AppScreen.home)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: _quoteSearch,
                hintText: "Search quotes...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              if (indexes.isEmpty)
                const _EmptyPanel(
                  icon: Icons.receipt_long_rounded,
                  title: "No quotes found",
                  subtitle: "Saved quotes will appear here.",
                )
              else
                for (final int index in indexes)
                  _QuoteCard(
                    clientName: _clientNameById(_store.quotes.clientIdAt(index)),
                    meta: _dateLabel(_store.quotes.timestampAt(index)),
                    total: _formatMoney(_store.quotes.totalCentsAt(index)),
                    status: "Saved",
                    statusColor: VigilColors.success,
                    statusBg: VigilColors.successSoft,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _templatesScreen() {
    final List<_QuoteTemplate> templates = [
      const _QuoteTemplate(
        name: "CCTV Basic",
        description: "4 cameras, one DVR, and installation labor",
        icon: Icons.videocam_rounded,
        itemNames: ["IP Camera 4MP"],
        serviceNames: ["CCTV Installation"],
      ),
      const _QuoteTemplate(
        name: "Gate + Motor",
        description: "Motor kit, control panel, and gate installation",
        icon: Icons.garage_rounded,
        itemNames: ["Gate Motor Kit", "Control Panel Pro"],
        serviceNames: ["Gate Motor Install"],
      ),
      const _QuoteTemplate(
        name: "Full Security",
        description: "Cameras, alarm setup, gate motor, and panel",
        icon: Icons.security_rounded,
        itemNames: ["IP Camera 4MP", "Gate Motor Kit", "Control Panel Pro"],
        serviceNames: ["CCTV Installation", "Alarm System Setup", "Gate Motor Install"],
      ),
    ];
    final String query = _templateSearch.text.trim().toLowerCase();
    final List<_QuoteTemplate> filtered = [
      for (final _QuoteTemplate template in templates)
        if (query.isEmpty ||
            template.name.toLowerCase().contains(query) ||
            template.description.toLowerCase().contains(query))
          template,
    ];

    return Column(
      children: [
        FlowHeader(title: "Templates", onBack: () => setState(() => _screen = AppScreen.home)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: _templateSearch,
                hintText: "Search templates...",
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              for (final _QuoteTemplate template in filtered)
                _TemplateCard(template: template, onUse: () => _useTemplate(template)),
            ],
          ),
        ),
      ],
    );
  }

  bool get _canSaveQuote => _selectedClientId != null && _store.draft.count > 0;

  void _saveAndContinue() {
    final int? clientId = _selectedClientId;
    if (clientId == null) return;
    final int total = _store.draft.computeTotals();
    final bool saved = _store.saveQuote(clientId);
    if (!saved) {
      _showSnack(_store.latestErrorMessage());
      return;
    }
    setState(() {
      _quoteSaved = true;
      _savedTotalCents = total;
      _screen = AppScreen.send;
    });
  }

  void _addDraftLine(int type, int refId) {
    final bool ok = _store.addDraftLine(type, refId, 1);
    if (!ok) _showSnack(_store.latestErrorMessage());
  }

  void _changeDraftQuantity(int type, int refId, int delta) {
    final int index = _store.draft.lineIndex(type, refId);
    if (index < 0) {
      if (delta > 0) _addDraftLine(type, refId);
      return;
    }
    final bool ok = _store.changeDraftQuantity(index, delta);
    if (!ok) _showSnack(_store.latestErrorMessage());
  }

  void _removeDraftLine(int type, int refId) {
    final int index = _store.draft.lineIndex(type, refId);
    if (index >= 0 && !_store.removeDraftLine(index)) _showSnack(_store.latestErrorMessage());
  }

  int _draftQuantity(int type, int refId) {
    final int index = _store.draft.lineIndex(type, refId);
    return index < 0 ? 0 : _store.draft.quantities[index];
  }

  int _draftTotalFor(int type) {
    var total = 0;
    for (var i = 0; i < _store.draft.count; i++) {
      if (_store.draft.types[i] == type) total += _store.draft.subtotalCents[i];
    }
    return total;
  }

  int _draftCountFor(int type) {
    var count = 0;
    for (var i = 0; i < _store.draft.count; i++) {
      if (_store.draft.types[i] == type) count++;
    }
    return count;
  }

  List<_DraftLineView> _draftLines(int type) {
    return [
      for (var i = 0; i < _store.draft.count; i++)
        if (_store.draft.types[i] == type)
          _DraftLineView(
            name: _store.nameFor(type, _store.draft.refIds[i]),
            quantity: _store.draft.quantities[i],
            subtotal: _formatMoney(_store.draft.subtotalCents[i]),
          ),
    ];
  }

  String _clientNameById(int id) {
    final int index = _store.clients.indexOfId(id);
    return index < 0 ? "Unknown client" : _store.clients.nameAt(index);
  }

  String _dateLabel(int millis) {
    if (millis <= 0) return "Draft";
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(millis);
    final DateTime now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    return "${date.month.toString().padLeft(2, "0")}/${date.day.toString().padLeft(2, "0")}/${date.year}";
  }

  IconData _catalogIcon(String name, {required bool isService}) {
    final String value = name.toLowerCase();
    if (value.contains("camera") || value.contains("cctv")) return Icons.videocam_rounded;
    if (value.contains("alarm")) return Icons.alarm_on_rounded;
    if (value.contains("gate") || value.contains("motor")) return Icons.garage_rounded;
    if (value.contains("panel")) return Icons.electrical_services_rounded;
    return isService ? Icons.handyman_rounded : Icons.inventory_2_rounded;
  }

  void _useTemplate(_QuoteTemplate template) {
    _store.clearDraft();
    for (final String name in template.serviceNames) {
      final int id = _catalogIdByName(_store.services, name);
      if (id > 0) _store.addDraftLine(quoteLineService, id, 1);
    }
    for (final String name in template.itemNames) {
      final int id = _catalogIdByName(_store.items, name);
      if (id > 0) _store.addDraftLine(quoteLineItem, id, name.contains("IP Camera") ? 4 : 1);
    }
    setState(() {
      _selectedClientId = null;
      _quoteSaved = false;
      _savedTotalCents = null;
      _screen = AppScreen.clients;
    });
  }

  int _catalogIdByName(ItemData data, String name) {
    for (var i = 0; i < data.count; i++) {
      if (data.nameAt(i) == name) return data.idAt(i);
    }
    return 0;
  }

  Future<void> _showClientDialog() async {
    final TextEditingController name = TextEditingController();
    final TextEditingController phone = TextEditingController();
    final TextEditingController email = TextEditingController();
    final TextEditingController address = TextEditingController();
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add Client"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(controller: name, label: "Name"),
                _DialogField(controller: phone, label: "Phone"),
                _DialogField(controller: email, label: "Email"),
                _DialogField(controller: address, label: "Address"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      final bool ok = _store.addClient(
        name.text.trim(),
        phone.text.trim(),
        email.text.trim(),
        address.text.trim(),
      );
      if (ok) {
        setState(() => _selectedClientId = _store.clients.idAt(_store.clients.count - 1));
      } else {
        _showSnack(_store.latestErrorMessage());
      }
    }
    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
  }

  Future<void> _showCatalogDialog({required bool isService}) async {
    final TextEditingController name = TextEditingController();
    final TextEditingController description = TextEditingController();
    final TextEditingController price = TextEditingController();
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isService ? "Add Service" : "Add Equipment"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(controller: name, label: "Name"),
                _DialogField(controller: description, label: "Description"),
                _DialogField(controller: price, label: "Price", keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      final int cents = _parseMoneyCents(price.text);
      final bool ok = isService
          ? _store.addService(name.text.trim(), description.text.trim(), cents)
          : _store.addItem(name.text.trim(), description.text.trim(), cents);
      if (!ok) _showSnack(_store.latestErrorMessage());
    }
    name.dispose();
    description.dispose();
    price.dispose();
  }

  void _showSnack(String message) {
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.ink,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 34),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Delforte",
            style: TextStyle(
              color: VigilColors.surface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewQuoteCard extends StatelessWidget {
  const _NewQuoteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: VigilRadius.featureRadius,
      child: Ink(
        decoration: BoxDecoration(
          gradient: VigilGradients.primaryAction,
          borderRadius: VigilRadius.featureRadius,
          boxShadow: VigilShadow.primaryLift,
        ),
        child: InkWell(
          borderRadius: VigilRadius.featureRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("New Quote", style: VigilType.title(color: VigilColors.surface, size: 19)),
                      const SizedBox(height: 4),
                      Text(
                        "Build a quote step by step",
                        style: VigilType.small(
                          color: Colors.white.withValues(alpha: 0.70),
                          size: 12,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: VigilRadius.cardRadius,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TapCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VigilIconBox(icon: icon, color: VigilColors.textSecondary, background: VigilColors.canvas),
            const SizedBox(height: 10),
            Text(label, style: _bodyStyle(weight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(subtitle, style: _smallStyle(color: VigilColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hintText, required this.onChanged});

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, color: VigilColors.textMuted),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.expanded,
    required this.selectedQuantity,
    required this.onToggle,
    required this.onAdd,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final String name;
  final String description;
  final String price;
  final IconData icon;
  final bool expanded;
  final int selectedQuantity;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool selected = selectedQuantity > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _TapCard(
        selected: expanded || selected,
        onTap: onToggle,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                children: [
                  VigilIconBox(
                    icon: icon,
                    color: expanded || selected ? VigilColors.primary : VigilColors.textMuted,
                    background: expanded || selected ? VigilColors.primarySoft : VigilColors.canvas,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _bodyStyle(weight: FontWeight.w700)),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _smallStyle(color: VigilColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!expanded)
                    Text(
                      selected ? "$selectedQuantity x $price" : price,
                      style: _smallStyle(color: VigilColors.textSecondary, weight: FontWeight.w700),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: VigilColors.textMuted,
                  ),
                ],
              ),
            ),
            if (expanded)
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: VigilColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 11, 15, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FieldSummary(label: "Unit Price", value: price),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FieldSummary(label: "Qty", value: selectedQuantity.toString()),
                      ),
                      const SizedBox(width: 8),
                      if (selected)
                        Row(
                          children: [
                            _RoundButton(icon: Icons.remove_rounded, onPressed: onDecrease),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "$selectedQuantity",
                                style: _bodyStyle(weight: FontWeight.w800),
                              ),
                            ),
                            _RoundButton(icon: Icons.add_rounded, onPressed: onIncrease),
                            IconButton(
                              tooltip: "Remove",
                              onPressed: onRemove,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: VigilColors.textMuted,
                              ),
                            ),
                          ],
                        )
                      else
                        FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text("Add"),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldSummary extends StatelessWidget {
  const _FieldSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VigilColors.canvas,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: _smallStyle(color: VigilColors.textMuted, size: 10)),
            const SizedBox(height: 4),
            Text(
              value,
              style: _smallStyle(color: VigilColors.textPrimary, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineGroup extends StatelessWidget {
  const _LineGroup({required this.title, required this.lines, required this.onEdit});

  final String title;
  final List<_DraftLineView> lines;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      trailing: IconButton(
        tooltip: "Edit $title",
        onPressed: onEdit,
        icon: const Icon(Icons.edit_rounded, size: 18),
      ),
      child: lines.isEmpty
          ? Text("No lines added", style: _smallStyle(color: VigilColors.textMuted, size: 13))
          : Column(
              children: [
                for (var i = 0; i < lines.length; i++)
                  _LineRow(line: lines[i], showDivider: i < lines.length - 1),
              ],
            ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.showDivider});

  final _DraftLineView line;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: showDivider ? VigilColors.border : Colors.transparent),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      line.name,
                      overflow: TextOverflow.ellipsis,
                      style: _smallStyle(color: VigilColors.textSecondary, size: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  VigilPill(
                    label: "${line.quantity}x",
                    color: VigilColors.textMuted,
                    background: VigilColors.canvas,
                  ),
                ],
              ),
            ),
            Text(
              line.subtotal,
              style: _smallStyle(color: VigilColors.textPrimary, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.title, required this.subtitle, required this.chips});

  final String title;
  final String subtitle;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: VigilColors.successSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_rounded, size: 34, color: VigilColors.success),
            ),
            const SizedBox(height: 13),
            Text(title, style: _titleStyle(size: 18), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: _smallStyle(color: VigilColors.textSecondary, size: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String chip in chips)
                  VigilPill(label: chip, color: VigilColors.primary, background: VigilColors.primarySoft),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onUse});

  final _QuoteTemplate template;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _TapCard(
        onTap: onUse,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              VigilIconBox(
                icon: template.icon,
                color: VigilColors.primary,
                background: VigilColors.primarySoft,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name, style: _bodyStyle(weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      template.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _smallStyle(color: VigilColors.textMuted),
                    ),
                  ],
                ),
              ),
              FilledButton(onPressed: onUse, child: const Text("Use")),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.clientName,
    required this.meta,
    required this.total,
    required this.status,
    required this.statusColor,
    required this.statusBg,
  });

  final String clientName;
  final String meta;
  final String total;
  final String status;
  final Color statusColor;
  final Color statusBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: VigilColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(clientName, style: _bodyStyle(weight: FontWeight.w700)),
                  ),
                  Text(
                    total,
                    style: _smallStyle(
                      color: VigilColors.textPrimary,
                      weight: FontWeight.w800,
                      size: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(meta, style: _smallStyle(color: VigilColors.textMuted)),
                  ),
                  VigilPill(label: status.toUpperCase(), color: statusColor, background: statusBg),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: _smallStyle(
                      color: VigilColors.textMuted,
                      size: 10,
                      weight: FontWeight.w900,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: VigilColors.ink, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: _bodyStyle(color: Colors.white, weight: FontWeight.w800, size: 15),
            ),
            Text(amount, style: _titleStyle(color: Colors.white, size: 26)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: VigilColors.primary,
          foregroundColor: VigilColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: VigilColors.textPrimary,
          side: VigilStroke.strong,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: VigilRadius.cardRadius),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: VigilColors.textSecondary),
        label: Text(label),
      ),
    );
  }
}

class _TapCard extends StatelessWidget {
  const _TapCard({required this.child, required this.onTap, this.selected = false});

  final Widget child;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(selected: selected, onTap: onTap, child: child);
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VigilSurface(
      background: VigilColors.canvas,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          VigilIconBox(
            icon: Icons.add_rounded,
            color: VigilColors.textMuted,
            background: VigilColors.border,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: _bodyStyle(color: VigilColors.textSecondary, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.text, required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? VigilColors.primary : VigilColors.inkElevated,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: VigilType.small(color: VigilColors.surface, size: 13, weight: FontWeight.w900),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: icon == Icons.add_rounded ? "Increase" : "Decrease",
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: _bodyStyle(weight: FontWeight.w800)),
        ),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VigilColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: VigilColors.textMuted),
            const SizedBox(height: 8),
            Text(title, style: _bodyStyle(weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _smallStyle(color: VigilColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VigilColors.canvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: VigilColors.textMuted, size: 36),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: _bodyStyle()),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text("Try Again")),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({required this.controller, required this.label, this.keyboardType});

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}

class _DraftLineView {
  const _DraftLineView({required this.name, required this.quantity, required this.subtotal});

  final String name;
  final int quantity;
  final String subtotal;
}

class _QuoteTemplate {
  const _QuoteTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.itemNames,
    required this.serviceNames,
  });

  final String name;
  final String description;
  final IconData icon;
  final List<String> itemNames;
  final List<String> serviceNames;
}

TextStyle _titleStyle({Color color = VigilColors.textPrimary, double size = 20}) {
  return VigilType.title(color: color, size: size);
}

TextStyle _bodyStyle({
  Color color = VigilColors.textPrimary,
  FontWeight weight = FontWeight.w600,
  double size = 14,
}) {
  return VigilType.body(color: color, size: size, weight: weight);
}

TextStyle _smallStyle({
  Color color = VigilColors.textMuted,
  FontWeight weight = FontWeight.w600,
  double size = 11,
}) {
  return VigilType.small(color: color, size: size, weight: weight);
}

String _initials(String value) {
  final List<String> parts = value
      .trim()
      .split(RegExp(r"\s+"))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return "--";
  if (parts.length == 1) return parts.first.characters.take(2).toUpperCase().toString();
  return "${parts.first.characters.first}${parts.last.characters.first}".toUpperCase();
}

String _formatMoney(int cents) {
  final int safe = cents < 0 ? 0 : cents;
  final int whole = safe ~/ 100;
  final int decimal = safe % 100;
  final String raw = whole.toString();
  final StringBuffer buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final int remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(".");
  }
  return "R\$ ${buffer.toString()},${decimal.toString().padLeft(2, "0")}";
}

int _parseMoneyCents(String value) {
  final String normalized = value.trim().replaceAll(".", "").replaceAll(",", ".");
  final double parsed = double.tryParse(normalized) ?? 0;
  if (parsed <= 0) return 0;
  return (parsed * 100).round();
}
