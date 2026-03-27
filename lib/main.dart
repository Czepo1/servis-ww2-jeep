import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = JeepRepository();
  await repository.load();
  runApp(MyApp(repository: repository));
}

Future<void> openBuiltInPdfHelper(
  BuildContext context,
  BuiltInPdfManual manual,
) async {
  try {
    final assetData = await rootBundle.load(manual.assetPath);
    final tempFile = File('${Directory.systemTemp.path}\\${manual.fileName}');
    await tempFile.writeAsBytes(
      assetData.buffer.asUint8List(),
      flush: true,
    );

    if (Platform.isWindows) {
      await Process.start('explorer.exe', [tempFile.path], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.start('open', [tempFile.path], runInShell: true);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [tempFile.path], runInShell: true);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF se nepodařilo otevřít.')),
      );
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository});

  final JeepRepository repository;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7A845B),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Servis WWII Jeepu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF131610),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: const Color(0xFFF5EEDB),
              displayColor: const Color(0xFFF5EEDB),
            ),
        cardTheme: CardThemeData(
          color: const Color(0xFF20251D),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF3C4432)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF20251D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF495240)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE3C17A), width: 1.4),
          ),
        ),
      ),
      home: JeepShell(repository: repository),
    );
  }
}
class JeepShell extends StatefulWidget {
  const JeepShell({super.key, required this.repository});

  final JeepRepository repository;

  @override
  State<JeepShell> createState() => _JeepShellState();
}

class _JeepShellState extends State<JeepShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        data: widget.repository.data,
        onSave: _saveAndRefresh,
        onNavigate: _openTab,
      ),
      ServiceHubPage(
        data: widget.repository.data,
        onSave: _saveAndRefresh,
        onBack: () => _openTab(0),
      ),
      LubricationPlanPage(
        data: widget.repository.data,
        onSave: _saveAndRefresh,
        onBack: () => _openTab(0),
      ),
      GuideLibraryPage(
        data: widget.repository.data,
        onSave: _saveAndRefresh,
        onBack: () => _openTab(0),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF31362A),
              Color(0xFF1B1F18),
              Color(0xFF11130F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: pages[currentIndex]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: const Color(0xFF181B16),
        indicatorColor: const Color(0xFF738053),
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Domů',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Servis',
          ),
          NavigationDestination(
            icon: Icon(Icons.opacity_outlined),
            selectedIcon: Icon(Icons.opacity),
            label: 'Mazání',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Návody',
          ),
        ],
      ),
    );
  }

  void _openTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> _saveAndRefresh() async {
    await widget.repository.save();
    if (mounted) {
      setState(() {});
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.data,
    required this.onSave,
    required this.onNavigate,
  });

  final JeepData data;
  final Future<void> Function() onSave;
  final void Function(int index) onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController historyController;
  late final TextEditingController originController;
  late final TextEditingController yearController;
  late final TextEditingController chassisController;
  late final TextEditingController engineController;
  late final TextEditingController lastServiceController;

  @override
  void initState() {
    super.initState();
    final profile = widget.data.profile;
    historyController = TextEditingController(text: profile.serviceHistory);
    originController = TextEditingController(text: profile.origin);
    yearController = TextEditingController(text: profile.year);
    chassisController = TextEditingController(text: profile.chassisNumber);
    engineController = TextEditingController(text: profile.engineNumber);
    lastServiceController = TextEditingController(text: profile.lastService);
  }

  @override
  void dispose() {
    historyController.dispose();
    originController.dispose();
    yearController.dispose();
    chassisController.dispose();
    engineController.dispose();
    lastServiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.data.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servisní knížka a návod pro WWII Jeep',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Přehled vozu, servisní historie, návody a mazací plán na jednom místě.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFD0C8AE),
                    ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _VehicleImageCard(
                            imagePath: profile.imagePath,
                            onPickImage: _pickImage,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 6,
                          child: _VehicleProfileCard(
                            historyController: historyController,
                            originController: originController,
                          yearController: yearController,
                          chassisController: chassisController,
                          engineController: engineController,
                          lastServiceController: lastServiceController,
                          onSave: _saveProfile,
                        ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VehicleImageCard(
                        imagePath: profile.imagePath,
                        onPickImage: _pickImage,
                      ),
                      const SizedBox(height: 20),
                      _VehicleProfileCard(
                        historyController: historyController,
                        originController: originController,
                        yearController: yearController,
                        chassisController: chassisController,
                        engineController: engineController,
                        lastServiceController: lastServiceController,
                        onSave: _saveProfile,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  HomeTile(
                    title: 'SERVIS',
                    subtitle: 'Motor, převodovka, nápravy a kontroly.',
                    icon: Icons.build_circle_outlined,
                    onTap: () => widget.onNavigate(1),
                  ),
                  HomeTile(
                    title: 'NÁVODY',
                    subtitle: 'Moderně přepsané postupy z historických zdrojů.',
                    icon: Icons.menu_book_outlined,
                    onTap: () => widget.onNavigate(3),
                  ),
                  HomeTile(
                    title: 'MAZÁNÍ',
                    subtitle: 'Lubrikační plán a mazací body krok za krokem.',
                    icon: Icons.opacity_outlined,
                    onTap: () => widget.onNavigate(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    final path = result?.files.single.path;
    if (path == null) {
      return;
    }

    setState(() {
      widget.data.profile.imagePath = path;
    });
    await widget.onSave();
  }

  Future<void> _saveProfile() async {
    widget.data.profile
      ..serviceHistory = historyController.text.trim()
      ..origin = originController.text.trim()
      ..year = yearController.text.trim()
      ..chassisNumber = chassisController.text.trim()
      ..engineNumber = engineController.text.trim()
      ..lastService = lastServiceController.text.trim();
    await widget.onSave();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Karta vozu byla uložena.')),
    );
  }
}

class _VehicleImageCard extends StatelessWidget {
  const _VehicleImageCard({
    required this.imagePath,
    required this.onPickImage,
  });

  final String imagePath;
  final Future<void> Function() onPickImage;

  @override
  Widget build(BuildContext context) {
    final file = imagePath.isNotEmpty ? File(imagePath) : null;
    final exists = file != null && file.existsSync();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Fotografie vozu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Nahrát obrázek'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF707A58), Color(0xFF2A2F24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: exists
                        ? DecorationImage(
                            image: FileImage(file!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: exists
                      ? const SizedBox.expand()
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.directions_car_filled_outlined,
                                  size: 64,
                                  color: Color(0xFFF6EFD9),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sem si můžeš nahrát konkrétní fotografii svého Jeepu.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleProfileCard extends StatelessWidget {
  const _VehicleProfileCard({
    required this.historyController,
    required this.originController,
    required this.yearController,
    required this.chassisController,
    required this.engineController,
    required this.lastServiceController,
    required this.onSave,
  });

  final TextEditingController historyController;
  final TextEditingController originController;
  final TextEditingController yearController;
  final TextEditingController chassisController;
  final TextEditingController engineController;
  final TextEditingController lastServiceController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Karta vozu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: historyController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Servisní historie vozu',
                hintText: 'Například generální oprava v roce 2014, výměna brzd...',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: originController,
                    decoration: const InputDecoration(labelText: 'Původ vozu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: yearController,
                    decoration: const InputDecoration(labelText: 'Rok výroby'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chassisController,
                    decoration:
                        const InputDecoration(labelText: 'Číslo podvozku'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: engineController,
                    decoration:
                        const InputDecoration(labelText: 'Číslo motoru'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastServiceController,
              decoration: const InputDecoration(
                labelText: 'Poslední servis',
                hintText: 'Například 12. 3. 2026 - výměna oleje v motoru',
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Uložit kartu vozu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTile extends StatefulWidget {
  const HomeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<HomeTile> createState() => _HomeTileState();
}

class _HomeTileState extends State<HomeTile> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = hovered ? const Color(0xFF556142) : const Color(0xFF2C3427);
    final accent = hovered ? const Color(0xFFFFE2A3) : const Color(0xFFF2E9CF);

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: hovered ? 1.02 : 1,
        child: SizedBox(
          width: 240,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hovered ? const Color(0xFFF0CA7D) : const Color(0xFF59634F),
                  width: hovered ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, size: 34, color: accent),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 0),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: hovered
                              ? const Color(0xFFFFF6E3)
                              : const Color(0xFFE1D7BB),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceHubPage extends StatelessWidget {
  const ServiceHubPage({
    super.key,
    required this.data,
    required this.onSave,
    required this.onBack,
  });

  final JeepData data;
  final Future<void> Function() onSave;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _AppSectionScaffold(
      title: 'Servisní celky',
      subtitle: 'Vyber oblast vozu a otevři podrobný checklist s termíny a kroky.',
      onBack: onBack,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: data.serviceCategories
            .map(
              (category) => CategoryTile(
                category: category,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ServiceChecklistPage(
                        category: category,
                        onSave: onSave,
                      ),
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
class CategoryTile extends StatefulWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: hovered ? 1.02 : 1,
        child: SizedBox(
          width: 250,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: hovered ? const Color(0xFF2E3729) : const Color(0xFF20251D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: hovered ? const Color(0xFFDDBB73) : const Color(0xFF46503D),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.category.icon, color: const Color(0xFFF2E5BF)),
                  const SizedBox(height: 14),
                  Text(
                    widget.category.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: hovered
                              ? const Color(0xFFFFDFA0)
                              : const Color(0xFFF3EDD9),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.category.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFD6CFB6),
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Sekcí: ${widget.category.sections.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFFC7D39E),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openBuiltInPdf(
    BuildContext context,
    BuiltInPdfManual manual,
  ) async {
    try {
      final assetData = await rootBundle.load(manual.assetPath);
      final tempFile = File('${Directory.systemTemp.path}\\${manual.fileName}');
      await tempFile.writeAsBytes(
        assetData.buffer.asUint8List(),
        flush: true,
      );

      if (Platform.isWindows) {
        await Process.start('explorer.exe', [tempFile.path], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.start('open', [tempFile.path], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [tempFile.path], runInShell: true);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF se nepodařilo otevřít.')),
        );
      }
    }
  }
}

class ServiceChecklistPage extends StatefulWidget {
  const ServiceChecklistPage({
    super.key,
    required this.category,
    required this.onSave,
  });

  final ServiceCategory category;
  final Future<void> Function() onSave;

  @override
  State<ServiceChecklistPage> createState() => _ServiceChecklistPageState();
}

class _ServiceChecklistPageState extends State<ServiceChecklistPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        backgroundColor: const Color(0xFF181B16),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3428), Color(0xFF151712)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemCount: widget.category.sections.length,
          itemBuilder: (context, index) {
            final section = widget.category.sections[index];
            return _ServiceSectionTile(
              section: section,
              onChanged: () async {
                setState(() {});
                await widget.onSave();
              },
              onOpen: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ServiceSectionDetailPage(
                      title: widget.category.title,
                      section: section,
                      onSave: widget.onSave,
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class _ServiceSectionTile extends StatelessWidget {
  const _ServiceSectionTile({
    required this.section,
    required this.onChanged,
    required this.onOpen,
  });

  final ServiceSection section;
  final Future<void> Function() onChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Checkbox(
                    value: section.completed,
                    onChanged: (value) async {
                      section.completed = value ?? false;
                      await onChanged();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                section.summary,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD8D1BB),
                    ),
              ),
              const Spacer(),
              Text(
                section.lastServiceDate.trim().isEmpty
                    ? 'Datum zatím není zapsané'
                    : 'Poslední servis: ${section.lastServiceDate}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFE2C98C),
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Otevřít detail',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFFC7D39E),
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceSectionDetailPage extends StatefulWidget {
  const ServiceSectionDetailPage({
    super.key,
    required this.title,
    required this.section,
    required this.onSave,
  });

  final String title;
  final ServiceSection section;
  final Future<void> Function() onSave;

  @override
  State<ServiceSectionDetailPage> createState() => _ServiceSectionDetailPageState();
}

class _ServiceSectionDetailPageState extends State<ServiceSectionDetailPage> {
  late final TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(text: widget.section.lastServiceDate);
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF181B16),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3428), Color(0xFF151712)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            section.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Checkbox(
                          value: section.completed,
                          onChanged: (value) async {
                            setState(() {
                              section.completed = value ?? false;
                            });
                            await widget.onSave();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.summary,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFD8D1BB),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Označ si, že je tento úkon splněný.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFBECCA3),
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Datum posledního servisu nebo výměny',
                        hintText: 'Například 15. 4. 2026',
                      ),
                      onChanged: (value) {
                        section.lastServiceDate = value.trim();
                      },
                      onSubmitted: (_) => widget.onSave(),
                    ),
                    const SizedBox(height: 16),
                    _DetailBlock(
                      title: 'Servisní postup',
                      items: section.steps,
                    ),
                    const SizedBox(height: 14),
                    _DetailBlock(
                      title: 'Kontrolní body',
                      items: section.checkpoints,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Zdroj: ${section.source}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFE2C98C),
                          ),
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

class LubricationPlanPage extends StatelessWidget {
  const LubricationPlanPage({
    super.key,
    required this.data,
    required this.onSave,
    required this.onBack,
  });

  final JeepData data;
  final Future<void> Function() onSave;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _AppSectionScaffold(
      title: 'Lubrikační a mazací plán',
      subtitle:
          'Nahoře je statický podvozkový plán. Mazání slouží jako rychlý přehled, servisní postupy zůstávají v sekci Servis.',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Podvozkový mazací plán',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Přehled dobového mazacího plánu podvozku. Podrobné servisní návody najdeš v jednotlivých servisních celcích.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFD8D1BB),
                        ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/podvozek_mazaci_plan.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class LubricationDetailPage extends StatefulWidget {
  const LubricationDetailPage({
    super.key,
    required this.entry,
    required this.onSave,
  });

  final LubricationEntry entry;
  final Future<void> Function() onSave;

  @override
  State<LubricationDetailPage> createState() => _LubricationDetailPageState();
}

class _LubricationDetailPageState extends State<LubricationDetailPage> {
  late final TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    dateController =
        TextEditingController(text: widget.entry.lastServiceDate);
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
        backgroundColor: const Color(0xFF181B16),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E3428), Color(0xFF151712)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.location,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFF0E0B2),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text('Mazivo: ${entry.lubricant}'),
                    Text('Interval: ${entry.interval}'),
                    const SizedBox(height: 16),
                    Text(
                      'Poloha / ilustrační pohled',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        entry.detailAssetPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Datum posledního mazání nebo kontroly',
                      ),
                      onChanged: (value) {
                        entry.lastServiceDate = value.trim();
                      },
                      onSubmitted: (_) => widget.onSave(),
                    ),
                    const SizedBox(height: 16),
                    _DetailBlock(
                      title: 'Návod pro laika',
                      items: entry.beginnerInstructions,
                    ),
                    const SizedBox(height: 14),
                    _DetailBlock(
                      title: 'Na co si dát pozor',
                      items: entry.checkpoints,
                    ),
                    const SizedBox(height: 14),
                    _LubricationChecklist(
                      entry: entry,
                      onChanged: () async {
                        setState(() {});
                        await widget.onSave();
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Zdroj: ${entry.source}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFE2C98C),
                          ),
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

  Future<void> _openBuiltInPdf(
    BuildContext context,
    BuiltInPdfManual manual,
  ) async {
    try {
      final assetData = await rootBundle.load(manual.assetPath);
      final tempFile = File('${Directory.systemTemp.path}\\${manual.fileName}');
      await tempFile.writeAsBytes(
        assetData.buffer.asUint8List(),
        flush: true,
      );

      if (Platform.isWindows) {
        await Process.start('explorer.exe', [tempFile.path], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.start('open', [tempFile.path], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [tempFile.path], runInShell: true);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF se nepodařilo otevřít.')),
        );
      }
    }
  }
}

class GuideLibraryPage extends StatelessWidget {
  const GuideLibraryPage({
    super.key,
    required this.data,
    required this.onSave,
    required this.onBack,
  });

  final JeepData data;
  final Future<void> Function() onSave;
  final VoidCallback onBack;

  static const List<BuiltInPdfManual> builtInManuals = [
    BuiltInPdfManual(
      title: 'Jeep Willys CZ',
      assetPath: 'assets/manuals/jeep_willys_CZ_free.pdf',
      fileName: 'jeep_willys_CZ_free.pdf',
      source: 'Vestavěný PDF manuál',
    ),
    BuiltInPdfManual(
      title: 'TM 9-803 Jeep MB/GPW',
      assetPath: 'assets/manuals/TM_9-803_Jeep_MB-GPW_TM-WW2_Free_edition.pdf',
      fileName: 'TM_9-803_Jeep_MB-GPW_TM-WW2_Free_edition.pdf',
      source: 'Vestavěný PDF manuál',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _AppSectionScaffold(
      title: 'Návody',
      subtitle: 'Vestavěné PDF manuály a užitečné odkazy pro servis WWII Jeepu.',
      onBack: onBack,
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF soubory',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tyto manuály jsou uložené přímo v aplikaci, takže je není potřeba znovu nahrávat.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFD9D1B6),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...builtInManuals.map(
            (manual) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BuiltInPdfManualCard(
                manual: manual,
                onOpen: () => openBuiltInPdfHelper(context, manual),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Užitečné odkazy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const _GuideLinkCard(
                    title: 'Kaiser Willys',
                    url: 'https://www.kaiserwillys.com',
                    summary:
                        'Praktické technické články, maziva, základní údržba a dobové díly.',
                  ),
                  const SizedBox(height: 12),
                  const _GuideLinkCard(
                    title: 'G503 Forum',
                    url: 'https://forums.g503.com',
                    summary:
                        'Diskuze restaurátorů, servisní zkušenosti a historické poznámky.',
                  ),
                  const SizedBox(height: 12),
                  const _GuideLinkCard(
                    title: 'MilitaryJeepParts.cz',
                    url: 'https://www.militaryjeepparts.cz',
                    summary:
                        'Český zdroj dílů a orientace v konkrétních komponentech WWII Jeepu.',
                  ),
                  const SizedBox(height: 12),
                  const _GuideLinkCard(
                    title: 'Greendot319',
                    url: 'https://forums.g503.com',
                    summary:
                        'Praktické renovátorské postupy a zkušenosti převzaté z vláken na G503.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BuiltInPdfManual {
  const BuiltInPdfManual({
    required this.title,
    required this.assetPath,
    required this.fileName,
    required this.source,
  });

  final String title;
  final String assetPath;
  final String fileName;
  final String source;
}

class _BuiltInPdfManualCard extends StatelessWidget {
  const _BuiltInPdfManualCard({
    required this.manual,
    required this.onOpen,
  });

  final BuiltInPdfManual manual;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F5C35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFF7E6BA),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manual.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        manual.source,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFE2C98C),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              manual.fileName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFD9D1B6),
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Otevřít PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualPlaceholderCard extends StatelessWidget {
  const _ManualPlaceholderCard({required this.manual});

  final ManualSection manual;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              manual.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Připraveno pro PDF: ${manual.originalHeading}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFE2C98C),
                  ),
            ),
            const SizedBox(height: 14),
            _DetailBlock(
              title: 'Co sem doplníme',
              items: manual.translation,
            ),
            const SizedBox(height: 14),
            _DetailBlock(
              title: 'Zjednodušený výklad',
              items: manual.simplifiedSteps,
            ),
            const SizedBox(height: 14),
            Text(
              'Zdroj: ${manual.source}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE2C98C),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideLinkCard extends StatelessWidget {
  const _GuideLinkCard({
    required this.title,
    required this.url,
    required this.summary,
  });

  final String title;
  final String url;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F241C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF46503D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            url,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE2C98C),
                ),
          ),
          const SizedBox(height: 6),
          Text(summary),
        ],
      ),
    );
  }
}

class _AppSectionScaffold extends StatelessWidget {
  const _AppSectionScaffold({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFFD2C9AF),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 7, color: Color(0xFFDDBB73)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LubricationChecklist extends StatelessWidget {
  const _LubricationChecklist({
    required this.entry,
    required this.onChanged,
  });

  final LubricationEntry entry;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kontrolní seznam',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...List.generate(entry.tasks.length, (index) {
          return CheckboxListTile(
            value: entry.taskStates[index],
            contentPadding: EdgeInsets.zero,
            title: Text(entry.tasks[index]),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) async {
              entry.taskStates[index] = value ?? false;
              await onChanged();
            },
          );
        }),
      ],
    );
  }
}

class JeepRepository {
  static const _storageKey = 'jeep_repository_v2';

  JeepData data = JeepData.sample().normalized();

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      data = JeepData.sample().normalized();
      return;
    }

    data = JeepData.fromMap(jsonDecode(raw) as Map<String, dynamic>).normalized();
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(data.toMap()));
  }
}

List<ServiceCategory> defaultServiceCategories() {
  return [
    ServiceCategory(
      id: 'motor',
      title: 'Motor',
      description: 'Olej, zapalování, palivo a běžný servis motoru L-134.',
      icon: Icons.precision_manufacturing_outlined,
      sections: [
        ServiceSection(
          title: 'Výměna motorového oleje',
          summary:
              'Postup pro běžnou výměnu motorového oleje tak, aby se podle něj dal udělat servis krok za krokem.',
          source: 'TM 9-803 / Kaiser Willys / G503',
          steps: [
            'Připrav si asi 4,7 litru motorového oleje, sběrnou nádobu, vhodný klíč na vypouštěcí šroub a čistý hadr.',
            'Motor krátce zahřej, aby olej lépe vytekl, ale nepracuj s nebezpečně horkým motorem.',
            'Jeep postav na rovnou plochu a zajisti ho proti pohybu.',
            'Najdi vypouštěcí šroub olejové vany, okolí nejprve očisti a potom šroub opatrně povol.',
            'Nech starý olej úplně vytéct a zkontroluj, zda v něm nejsou kovové částice nebo voda.',
            'Vypouštěcí šroub vrať zpět a dotáhni s citem.',
            'Přes plnicí hrdlo nalij předepsané množství nového oleje. Pro dnešní běžný provoz se v praxi často používá 15W-40; dobově manuály uvádějí sezónní viskozity typu SAE 30 podle teploty.',
            'Počkej chvíli, zkontroluj hladinu na měrce a případně jemně dolij.',
            'Motor krátce nastartuj, nech ho běžet na volnoběh a znovu zkontroluj těsnost i hladinu.',
          ],
          checkpoints: [
            'Pro běžný dnešní provoz je praktická volba 15W-40; při striktně dobovém přístupu se drž sezónních SAE hodnot z manuálu.',
            'Objem náplně je přibližně 4,7 litru.',
            'Hladina na měrce musí být v normě.',
            'Vypouštěcí šroub nesmí prosakovat.',
            'Motor po výměně nesmí vydávat nezvyklé klepání.',
          ],
        ),
        ServiceSection(
          title: 'Kontrola zapalování a svíček',
          summary:
              'Základní údržba při horším startu, nepravidelném chodu nebo slabém výkonu motoru.',
          source: 'TM 9-803 / G503',
          steps: [
            'Nech motor vychladnout a odpoj kabel svíčky vždy jen u jednoho válce.',
            'Vyšroubuj svíčku, zkontroluj její barvu a jemně odstraň usazeniny.',
            'Změř a uprav mezeru elektrod podle dobového předpisu.',
            'Stejným způsobem zkontroluj všechny svíčky.',
            'Prohlédni víčko rozdělovače, palec a kabely zapalování.',
            'Po složení motor nastartuj a sleduj, zda běží pravidelně.',
          ],
          checkpoints: [
            'Závit ve hlavě nesmí být poškozený.',
            'Kabely musí po montáži pevně držet.',
            'Svíčky nesmí být silně očazené ani zalité olejem.',
            'Motor musí po složení běžet pravidelně.',
          ],
        ),
        ServiceSection(
          title: 'Kontrola palivové soustavy',
          summary:
              'Praktický postup před jízdou nebo po delším odstavení vozu.',
          source: 'TM 9-803 / Kaiser Willys',
          steps: [
            'Zkontroluj, zda kolem palivového čerpadla, karburátoru a hadic není cítit benzín.',
            'Projdi vedení paliva od nádrže k motoru a hledej praskliny, uvolněné spoje nebo prosakování.',
            'Vyčisti sedimentační misku nebo filtr, pokud je znečištěný.',
            'Po nastartování sleduj, zda motor drží volnoběh a plynule reaguje na plyn.',
          ],
          checkpoints: [
            'Nikde nesmí prosakovat palivo.',
            'Karburátor nesmí přetékat.',
            'Motor musí držet volnoběh bez kolísání.',
          ],
        ),
        ServiceSection(
          title: 'Čištění olejového filtru',
          summary:
              'Podrobný postup pro servis olejového filtru, aby výměna oleje nebyla neúplná.',
          source: 'TM 9-803 / Kaiser Willys',
          steps: [
            'Před prací si připrav čistý hadr, vhodný klíč a novou filtrační vložku nebo potřebný servisní materiál podle typu filtru.',
            'Po vypuštění oleje očisti okolí tělesa olejového filtru, aby se dovnitř nedostaly nečistoty.',
            'Opatrně otevři víko filtru a vyjmi starou vložku nebo znečištěnou náplň.',
            'Vnitřek tělesa filtru vytři dočista a zkontroluj stav těsnění víka.',
            'Vlož novou filtrační vložku, uzavři víko a dotáhni ho rovnoměrně.',
            'Po nastartování motoru zkontroluj, zda kolem filtru neprosakuje olej.',
          ],
          checkpoints: [
            'Těsnění víka filtru musí dobře dosedat.',
            'Kolem tělesa filtru nesmí být čerstvý únik oleje.',
            'Filtr musí být servisovaný současně s výměnou oleje.',
          ],
        ),
        ServiceSection(
          title: 'Čištění vzduchového filtru',
          summary:
              'Postup pro běžnou kontrolu a vyčištění olejového vzduchového filtru motoru.',
          source: 'TM 9-803 / G503',
          steps: [
            'Sundej víko nebo spodní misku vzduchového filtru podle provedení.',
            'Vylij starou náplň, pokud je spodní část plněná olejem, a odstraň usazený prach a nečistoty.',
            'Vyčisti vnitřek filtru podle dobového postupu a nech jednotlivé části oschnout.',
            'Doplň správné množství čistého oleje do misky, pokud to typ filtru vyžaduje.',
            'Filtr pečlivě slož zpět a ověř, že nikde nepřisává falešný vzduch.',
          ],
          checkpoints: [
            'V misce musí být správná hladina oleje, pokud je filtr olejového typu.',
            'Filtr nesmí být ucpaný blátem ani zaschlým prachem.',
            'Spoje sání musí po montáži dobře těsnit.',
          ],
        ),
        ServiceSection(
          title: 'Kontrola a čištění palivového filtru',
          summary:
              'Praktický návod pro sedimentační misku a základní palivový filtr, aby motor netrpěl nedostatkem paliva.',
          source: 'TM 9-803 / Kaiser Willys',
          steps: [
            'Uzavři přívod paliva, pokud je to na voze možné, a připrav si hadr na zachycení zbytkového benzínu.',
            'Opatrně rozeber sedimentační misku nebo těleso filtru.',
            'Vyčisti skleněnou misku, sítko i těsnicí plochy od nečistot a usazenin.',
            'Zkontroluj těsnění a při poškození ho vyměň.',
            'Slož filtr zpět, otevři přívod paliva a sleduj, zda nikde neprosakuje benzín.',
          ],
          checkpoints: [
            'Miska a sítko musí být čisté.',
            'Nikde nesmí prosakovat palivo.',
            'Motor po vyčištění musí reagovat plynuleji a bez výpadků paliva.',
          ],
        ),
      ],
    ),
    ServiceCategory(
      id: 'prevodovka',
      title: 'Převodovka',
      description: 'Olej, řazení, těsnost a běžná péče o T-84.',
      icon: Icons.settings_outlined,
      sections: [
        ServiceSection(
          title: 'Kontrola a doplnění oleje',
          summary:
              'Jednoduchý servisní postup pro kontrolu hladiny a doplnění oleje v převodovce.',
          source: 'TM 9-1803B / G503',
          steps: [
            'Nejprve očisti okolí kontrolní zátky, aby se nečistoty nedostaly dovnitř.',
            'Povol kontrolní zátku na boku převodovky.',
            'Správná hladina je těsně u spodní hrany otvoru.',
            'Pokud olej chybí, doplň ho pomalu olejem SAE 90 bez EP/hypoidních aditiv. Jako dnešní náhrada se hodí například minerální GL-1, případně opatrně GL-4 podle materiálů uvnitř.',
            'Zátku vrať zpět, dotáhni a po krátké jízdě zkontroluj těsnost.',
          ],
          checkpoints: [
            'Do T-84 nepatří 85W-140 hypoidní olej; na fórech G503 se pro převodovku doporučuje SAE 90 bez EP/hypoidních přísad.',
            'Hladina nesmí být pod kontrolním otvorem.',
            'Po dotažení nesmí kolem zátky prosakovat olej.',
            'Řazení musí zůstat plynulé i po zkušební jízdě.',
          ],
        ),
        ServiceSection(
          title: 'Kontrola chodu řazení',
          summary:
              'Když jde řazení ztuha nebo drhne, začni základní kontrolou kulisy a mechaniky.',
          source: 'G503 / TM 9-1803B',
          steps: [
            'Se stojícím vozem projdi všechny polohy řadicí páky a vnímej, zda se pohybuje volně.',
            'Zkontroluj stav horního víka převodovky a případné úniky oleje.',
            'Pokud je řazení nepřesné, zkontroluj vůle a opotřebení mechanismu.',
            'Po servisu proveď krátkou klidnou jízdu a ověř, že rychlosti nevyskakují.',
          ],
          checkpoints: [
            'Řadicí páka nesmí mít nadměrnou vůli.',
            'Rychlosti musí jít zařadit bez násilí.',
            'Převodovka nesmí při jízdě nadměrně hučet.',
          ],
        ),
      ],
    ),
    ServiceCategory(
      id: 'rozvodovka',
      title: 'Rozvodovka',
      description: 'Náhon 4x4, hladina oleje a kontrola ovládacích pák.',
      icon: Icons.alt_route_outlined,
      sections: [
        ServiceSection(
          title: 'Kontrola oleje v rozvodovce',
          summary:
              'Praktický servis rozvodovky před jízdou nebo po zjištěném úniku oleje.',
          source: 'TM 9-1803B / G503',
          steps: [
            'Rozvodovku zvenku očisti od bláta a starého oleje.',
            'Povol kontrolní šroub a prstem opatrně ověř hladinu oleje.',
            'Pokud je hladina nízko, doplň olej po spodní hranu kontrolního otvoru. Pro Dana 18 se drž SAE 90 bez hypoidních EP přísad, stejně jako u převodovky.',
            'Po dotažení zkontroluj, zda se páky pohybují lehce a bez drhnutí.',
          ],
          checkpoints: [
            'Ani do rozvodovky se běžně nedává 85W-140 hypoid; hypoidní olej patří hlavně do diferenciálů.',
            'Skříň nesmí být výrazně zamaštěná od nového úniku.',
            'Páka náhonu přední nápravy musí mít jistou polohu.',
            'Po servisu nesmí být slyšet nové mechanické zvuky.',
          ],
        ),
      ],
    ),
    ServiceCategory(
      id: 'napravy',
      title: 'Nápravy',
      description: 'Diferenciály, ložiska, těsnost a běžná kontrola náprav.',
      icon: Icons.hub_outlined,
      sections: [
        ServiceSection(
          title: 'Kontrola diferenciálů',
          summary:
              'Základní péče o přední i zadní diferenciál při běžném servisu.',
          source: 'TM 9-803 / Kaiser Willys / G503',
          steps: [
            'Očisti víko diferenciálu a zkontroluj, zda kolem něj není čerstvý olej.',
            'Povol kontrolní zátku a ověř, že olej sahá ke spodní hraně otvoru.',
            'Při doplňování používej hypoidní převodový olej určený pro diferenciály. Pro běžný dnešní provoz se často používá 85W-140 nebo 80W-90 podle klimatu a stavu nápravy.',
            'Po jízdě znovu zkontroluj, zda diferenciál nezůstává vlhký od úniku.',
          ],
          checkpoints: [
            'Hypoidní olej patří do diferenciálů, ne do T-84 a Dana 18.',
            'Těsnění víka nesmí slzet.',
            'Po jízdě nesmí být slyšet hučení ložisek navíc.',
            'Kola nesmí mít výraznou vůli od ložisek.',
          ],
        ),
      ],
    ),
    ServiceCategory(
      id: 'rizeni',
      title: 'Řízení',
      description: 'Vůle řízení, táhla, čepy a převodka řízení.',
      icon: Icons.control_camera_outlined,
      sections: [
        ServiceSection(
          title: 'Kontrola vůlí řízení',
          summary:
              'Bezpečnostní kontrola řízení před jízdou a po zásahu do podvozku.',
          source: 'Greendot319 / G503',
          steps: [
            'Postav vůz na rovinu a kola natoč přímo.',
            'Jemně pohybuj volantem a sleduj, kdy začnou reagovat kola.',
            'Zkontroluj spojovací tyče, čepy a převodku řízení.',
            'Pokud je vůle nadměrná, proveď seřízení podle manuálu.',
          ],
          checkpoints: [
            'Volant nesmí mít nadměrnou mrtvou vůli.',
            'Na čepech nesmí chybět mazivo ani pojistné prvky.',
            'Řízení se nesmí vracet trhavě.',
          ],
        ),
      ],
    ),
    ServiceCategory(
      id: 'brzdy',
      title: 'Brzdy',
      description: 'Pedál, bubny, obložení a základní seřízení brzd.',
      icon: Icons.car_repair_outlined,
      sections: [
        ServiceSection(
          title: 'Základní kontrola brzdového systému',
          summary:
              'Přehledný postup před jízdou nebo po delším odstavení vozu.',
          source: 'TM 9-803 / Kaiser Willys',
          steps: [
            'Prohlédni brzdové vedení a spoje, zda nejsou vlhké od kapaliny.',
            'Se stojícím vozem několikrát sešlápni pedál a sleduj jeho odpor.',
            'Pokud jde pedál příliš hluboko, zkontroluj systém ještě před jízdou.',
            'Při sundaném kole ověř stav bubnu, obložení a vratných pružin.',
          ],
          checkpoints: [
            'Pedál nesmí pomalu propadat.',
            'Brzdy musí zabírat rovnoměrně.',
            'Na bubnech nesmí být mastnota.',
          ],
        ),
        ServiceSection(
          title: 'Seřízení brzd po servisu',
          summary:
              'Po výměně dílů nebo po delším odstavení je potřeba brzdy jemně dorovnat a vyzkoušet.',
          source: 'TM 9-803 / Military Jeep Parts',
          steps: [
            'Po montáži bubnu nastav brzdu podle dobového postupu tak, aby čelisti nebrzdily trvale.',
            'Stejné základní nastavení proveď na všech kolech.',
            'Po spuštění vozu na kola proveď krátkou zkušební jízdu na bezpečném místě.',
            'Brzdy při jízdě jemně vyzkoušej a sleduj, zda vůz netáhne na jednu stranu.',
          ],
          checkpoints: [
            'Vůz nesmí při brzdění táhnout do strany.',
            'Kolo se po uvolnění brzdy musí volně otáčet.',
            'Po jízdě nesmí být některý buben výrazně přehřátý.',
          ],
        ),
      ],
    ),
    ServiceCategory(
      id: 'elektrika',
      title: 'Elektrika',
      description: 'Baterie, startování, dobíjení, světla a kabeláž.',
      icon: Icons.electrical_services_outlined,
      sections: [
        ServiceSection(
          title: 'Kontrola baterie a startovací soustavy',
          summary:
              'Postup pro chvíle, kdy Jeep špatně startuje nebo po delším stání nechce točit.',
          source: 'TM 9-803 / G503',
          steps: [
            'Zkontroluj, zda jsou póly baterie čisté a pevně dotažené.',
            'Podívej se na kostřící kabel a hlavní přívod ke startéru.',
            'Pokud startér točí pomalu, ověř stav nabití baterie a čistotu kontaktů.',
            'Po nastartování sleduj, zda dobíjení nezůstává bez odezvy.',
          ],
          checkpoints: [
            'Póly baterie nesmí být zoxidované.',
            'Kabely nesmí být volné ani zahřáté.',
            'Startér musí točit bez přerušování.',
          ],
        ),
        ServiceSection(
          title: 'Kontrola světel a kabeláže',
          summary:
              'Jednoduchá prohlídka světel, spínačů a vodičů před jízdou nebo po opravě.',
          source: 'TM 9-1825E / G503',
          steps: [
            'Zapni obrysová světla, hlavní světla i brzdové světlo a ověř jejich funkci.',
            'Zkontroluj, zda nejsou objímky uvolněné nebo zkorodované.',
            'Projdi viditelné vedení a hledej poškozenou izolaci nebo neodborné spoje.',
            'Před uzavřením servisu ověř znovu všechny funkce světel v klidu i při běžícím motoru.',
          ],
          checkpoints: [
            'Všechna světla musí svítit stabilně.',
            'Nikde nesmí být obnažený vodič.',
            'Pojistky a spoje nesmí být přehřáté.',
          ],
        ),
      ],
    ),
    ServiceCategory(
      id: 'chlazeni',
      title: 'Chlazení',
      description: 'Chladič, hadice, voda v systému a sledování teploty.',
      icon: Icons.ac_unit_outlined,
      sections: [
        ServiceSection(
          title: 'Kontrola chladicí soustavy',
          summary:
              'Přehledný postup před delší jízdou nebo při podezření na přehřívání motoru.',
          source: 'TM 9-803 / Kaiser Willys',
          steps: [
            'Kontrolu prováděj vždy na vychladlém motoru.',
            'Víčko chladiče otevírej až po ověření, že v systému není tlak.',
            'Zkontroluj výšku hladiny kapaliny nebo vody v chladiči.',
            'Prohlédni hadice, spony a spodní část chladiče, zda nejsou vlhké od úniku.',
          ],
          checkpoints: [
            'Hladina musí být přiměřená, ne úplně po okraj.',
            'Hadice nesmí být prasklé ani měkké.',
            'Chladič nesmí prosakovat.',
          ],
        ),
        ServiceSection(
          title: 'Postup při přehřívání motoru',
          summary:
              'Základní kroky, které pomohou bezpečně zastavit a zkontrolovat příčinu vysoké teploty.',
          source: 'TM 9-803 / praktická dílenská úprava',
          steps: [
            'Pokud teplota výrazně stoupá, zastav na bezpečném místě a motor nevypínej prudce pod zátěží.',
            'Nech motor chvíli zklidnit na volnoběh, pokud nehrozí okamžité poškození.',
            'Po vychladnutí zkontroluj hladinu v chladiči, stav řemene a čistotu čela chladiče.',
            'Neotvírej víčko horkého chladiče prudce.',
          ],
          checkpoints: [
            'Řemen ventilátoru musí být napnutý a nepoškozený.',
            'Chladič musí mít volný průchod vzduchu.',
            'Po dolití musí systém zůstat těsný.',
          ],
        ),
      ],
    ),
  ];
}

class JeepData {
  JeepData({
    required this.profile,
    required this.serviceCategories,
    required this.lubricationEntries,
    required this.pdfManuals,
    required this.guides,
    required this.manuals,
  });

  JeepProfile profile;
  List<ServiceCategory> serviceCategories;
  List<LubricationEntry> lubricationEntries;
  List<PdfManual> pdfManuals;
  List<GuideNote> guides;
  List<ManualSection> manuals;

  factory JeepData.sample() {
    return JeepData(
      profile: JeepProfile.empty(),
      serviceCategories: [
        ServiceCategory(
          id: 'motor',
          title: 'Motor',
          description: 'Olej, chlazení, zapalování a pravidelná kontrola chodu.',
          icon: Icons.precision_manufacturing_outlined,
          sections: [
            ServiceSection(
              title: 'Výměna motorového oleje',
              summary: 'Základní servis motoru L-134 po zahřátí a bezpečném odstavení.',
              source: 'Kaiser Willys / TM 9-803',
              steps: [
                'Nejprve motor krátce zahřej, aby byl olej tekutější a snáze vytekl.',
                'Jeep postav na rovnou plochu a pod olejovou vanu dej vhodnou nádobu.',
                'Najdi vypouštěcí šroub na spodní straně olejové vany a před povolením ho očisti.',
                'Šroub opatrně povol, nech olej zcela vytéct a zkontroluj, zda v oleji nejsou kovové částice.',
                'Šroub vrať zpět, dotáhni s citem a doplň předepsané množství oleje.',
                'Po nastartování nech motor krátce běžet a potom znovu ověř hladinu na měrce.',
              ],
              checkpoints: [
                'Hladina na měrce musí být v normě.',
                'Vypouštěcí šroub nesmí prosakovat.',
                'Motor po výměně nesmí vydávat nezvyklé klepání.',
              ],
            ),
            ServiceSection(
              title: 'Kontrola zapalovacích svíček',
              summary: 'Pravidelná kontrola stavu svíček pomáhá odhalit směs i kondici motoru.',
              source: 'G503 / TM 10',
              steps: [
                'Nech motor vychladnout a odpoj kabel svíčky vždy jen u jednoho válce.',
                'Svíčku vyšroubuj vhodným klíčem a označ si její polohu.',
                'Zkontroluj barvu elektrody a jemně odstraň usazeniny.',
                'Ověř správnou mezeru elektrod podle manuálu a svíčku vrať zpět.',
              ],
              checkpoints: [
                'Závit ve hlavě nesmí být poškozený.',
                'Kabely musí po montáži pevně držet.',
                'Motor musí po složení běžet pravidelně.',
              ],
            ),
          ],
        ),
        ServiceCategory(
          id: 'prevodovka',
          title: 'Převodovka',
          description: 'Hladina oleje, těsnost a chod řazení.',
          icon: Icons.settings_outlined,
          sections: [
            ServiceSection(
              title: 'Kontrola a doplnění oleje',
              summary: 'Převodovka T-84 vyžaduje čistý olej a pravidelnou kontrolu hladiny.',
              source: 'Kaiser Willys / G503',
              steps: [
                'Před kontrolou očisti okolí kontrolního šroubu, aby se nečistoty nedostaly dovnitř.',
                'Povol kontrolní zátku na boku skříně převodovky.',
                'Hladina má být těsně u spodní hrany otvoru.',
                'Pokud olej chybí, doplň ho pomalu vhodným převodovým olejem.',
              ],
              checkpoints: [
                'Po dotažení nesmí kolem zátky prosakovat olej.',
                'Řazení musí zůstat plynulé i po zkušební jízdě.',
              ],
            ),
          ],
        ),
        ServiceCategory(
          id: 'rozvodovka',
          title: 'Rozvodovka',
          description: 'Rozdělení náhonu, kontrola těsnosti a ovládacích pák.',
          icon: Icons.alt_route_outlined,
          sections: [
            ServiceSection(
              title: 'Kontrola oleje v rozvodovce',
              summary: 'Rozvodovka musí mít správnou hladinu oleje pro tichý a bezpečný chod.',
              source: 'TM 9-1803B / G503',
              steps: [
                'Rozvodovku před kontrolou zvenku očisti od bláta a starého oleje.',
                'Povol kontrolní šroub a prstem opatrně ověř hladinu oleje.',
                'Pokud je hladina nízko, doplň olej po spodní hranu kontrolního otvoru.',
                'Po dotažení zkontroluj, zda se páky pohybují lehce a bez drhnutí.',
              ],
              checkpoints: [
                'Skříň nesmí být výrazně zamaštěná od nového úniku.',
                'Páka náhonu přední nápravy musí mít jistou polohu.',
              ],
            ),
          ],
        ),
        ServiceCategory(
          id: 'napravy',
          title: 'Nápravy',
          description: 'Diferenciály, čepy, ložiska a mazací body.',
          icon: Icons.hub_outlined,
          sections: [
            ServiceSection(
              title: 'Kontrola diferenciálů',
              summary: 'Přední i zadní diferenciál je potřeba udržovat čistý a těsný.',
              source: 'Kaiser Willys / TM 9-803',
              steps: [
                'Očisti víko a zkontroluj, zda kolem něj není čerstvý olej.',
                'Povol kontrolní zátku a ověř, že olej sahá ke spodní hraně otvoru.',
                'Při doplňování používej jen doporučený převodový olej.',
              ],
              checkpoints: [
                'Těsnění víka nesmí slzet.',
                'Po jízdě nesmí být slyšet hučení ložisek navíc.',
              ],
            ),
          ],
        ),
        ServiceCategory(
          id: 'rizeni',
          title: 'Řízení',
          description: 'Mazání převodky řízení, spojovacích tyčí a kontrola vůlí.',
          icon: Icons.control_camera_outlined,
          sections: [
            ServiceSection(
              title: 'Kontrola vůlí řízení',
              summary: 'Správná vůle v řízení je zásadní pro bezpečnou jízdu.',
              source: 'Greendot319 / G503',
              steps: [
                'Postav vůz na rovinu a kola natoč přímo.',
                'Jemně pohybuj volantem a sleduj, kdy začnou reagovat kola.',
                'Zkontroluj spojovací tyče, čepy a převodku řízení.',
                'Pokud je vůle nadměrná, proveď seřízení podle manuálu.',
              ],
          checkpoints: [
            'Volant nesmí mít nadměrnou mrtvou vůli.',
            'Na čepech nesmí chybět mazivo ani pojistné prvky. Pro běžný dnešní servis je praktické víceúčelové lithiové mazivo NLGI 2; české mazivo LV 2-3 lze použít jako moderní ekvivalent do maznic.',
          ],
        ),
      ],
    ),
        ServiceCategory(
          id: 'brzdy',
          title: 'Brzdy',
          description: 'Seřízení, kontrola bubnů a sledování úniků.',
          icon: Icons.car_repair_outlined,
          sections: [
            ServiceSection(
              title: 'Kontrola brzdového systému',
              summary: 'Pravidelně prověřuj bubny, vedení i reakci pedálu.',
              source: 'TM 9-803 / Kaiser Willys',
              steps: [
                'Prohlédni vedení a spojky, zda nejsou vlhké od kapaliny.',
                'Zkontroluj chod pedálu a jeho odpor.',
                'Při sundaném kole ověř stav bubnu, obložení a vratných pružin.',
              ],
              checkpoints: [
                'Pedál nesmí pomalu propadat.',
                'Brzdy musí zabírat rovnoměrně.',
              ],
            ),
          ],
        ),
      ],
      lubricationEntries: [
        LubricationEntry(
          id: 'mazani_motor',
          title: 'Motor',
          location: 'Mazání motoru a kontrola olejového hospodářství',
          icon: Icons.precision_manufacturing_outlined,
          mapView: LubricationMapView.side,
          hotspotX: 0.33,
          hotspotY: 0.39,
          lubricant: 'Motorový olej 15W-40 pro běžný dnešní provoz; dobově sezónně SAE 30 / SAE 20 / SAE 10 podle teploty',
          interval: 'Pravidelně podle provozu a po delším odstavení',
          source: 'Kaiser Willys / TM 9-803',
          beginnerInstructions: [
            'Nejprve motor zahřej jen natolik, aby byl olej tekutější, ale nebyl nebezpečně horký.',
            'Očisti okolí víčka plnicího hrdla i vypouštěcího šroubu.',
            'Najdi měrku a před odečtem ji otři čistým hadrem.',
            'Po výměně nebo doplnění vždy znovu zkontroluj hladinu na měrce.',
          ],
          checkpoints: [
            '15W-40 je praktická dnešní volba pro L-134; při dobové interpretaci se drž teplotních SAE hodnot z manuálu.',
            'Hladina na měrce musí být v normě.',
            'Kolem filtru a vany nesmí být nový únik oleje.',
          ],
          tasks: [
            'Očistit okolí měrky a plnicího hrdla',
            'Zkontrolovat hladinu na měrce',
            'Prověřit těsnost vany a filtru',
          ],
        ),
        LubricationEntry(
          id: 'mazani_prevodovka',
          title: 'Převodovka',
          location: 'Skříň převodovky T-84',
          icon: Icons.settings_outlined,
          mapView: LubricationMapView.underbody,
          hotspotX: 0.50,
          hotspotY: 0.56,
          lubricant: 'SAE 90 bez EP/hypoidních aditiv; prakticky minerální GL-1, případně opatrně GL-4',
          interval: 'Pravidelná kontrola hladiny a po netěsnostech ihned',
          source: 'G503 / TM 10',
          beginnerInstructions: [
            'Před povolením kontrolní zátky důkladně očisti její okolí.',
            'Najdi kontrolní otvor na boku převodovky a zátku povol vhodným klíčem.',
            'Hladina má být u spodní hrany otvoru; doplňuj pomalu, aby olej nezačal vytékat ven příliš brzy.',
          ],
          checkpoints: [
            'Do T-84 nepatří 85W-140 hypoidní olej.',
            'Po dotažení zátky musí být skříň suchá.',
            'Po jízdě musí převodovka řadit bez drhnutí navíc.',
          ],
          tasks: [
            'Očistit kontrolní zátku',
            'Zkontrolovat hladinu oleje',
            'Po dotažení ověřit těsnost skříně',
          ],
        ),
        LubricationEntry(
          id: 'mazani_rizeni',
          title: 'Řízení',
          location: 'Převodka řízení a maznice na spojovacích bodech',
          icon: Icons.control_camera_outlined,
          mapView: LubricationMapView.side,
          hotspotX: 0.48,
          hotspotY: 0.46,
          lubricant: 'Víceúčelové lithiové mazivo NLGI 2; v české praxi lze použít i LV 2-3 do maznic a čepů',
          interval: 'Pravidelně při servisní kontrole podvozku',
          source: 'Greendot319 / G503',
          beginnerInstructions: [
            'Najdi všechny maznice na táhlech a před mazáním je otři od prachu.',
            'Mazací lis přitlač rovně, aby tuk neutíkal kolem hlavice.',
            'Mazej jen do chvíle, kdy je vidět čerstvé mazivo nebo ucítíš odpor.',
          ],
          checkpoints: [
            'Mazivo má být plastické a držet v maznicích; nevol tekutý převodový olej do běžných čepů.',
            'Měchovky a prachovky nesmí být roztržené.',
            'Řízení musí po mazání chodit plynule.',
          ],
          tasks: [
            'Očistit maznice před lisováním tuku',
            'Promazat čepy a spojovací body',
            'Po mazání prověřit lehkost chodu řízení',
          ],
        ),
        LubricationEntry(
          id: 'mazani_predni_diferencial',
          title: 'Přední diferenciál',
          location: 'Skříň předního diferenciálu a kontrolní zátka',
          icon: Icons.hub_outlined,
          mapView: LubricationMapView.underbody,
          hotspotX: 0.39,
          hotspotY: 0.33,
          lubricant: 'Hypoidní převodový olej pro diferenciály, prakticky 80W-90 nebo 85W-140 podle klimatu a vůlí',
          interval: 'Pravidelná kontrola hladiny a po brodění ihned',
          source: 'War Department Lubrication Guide No. 501',
          beginnerInstructions: [
            'Najdi skříň předního diferenciálu mezi předními koly a okolí zátky očisti hadrem.',
            'Povol kontrolní zátku a prstem ověř, zda je olej u spodní hrany otvoru.',
            'Pokud hladina klesla, doplň olej po správnou úroveň a zátku znovu pečlivě dotáhni.',
          ],
          checkpoints: [
            'Hypoidní olej je vhodný pro diferenciál.',
            'Kolem víka diferenciálu nesmí být čerstvý únik oleje.',
            'Po jízdě nesmí být slyšet neobvyklé hučení z přední nápravy.',
          ],
          tasks: [
            'Očistit kontrolní zátku a víko diferenciálu',
            'Ověřit hladinu oleje v otvoru',
            'Po dotažení zkontrolovat těsnost',
          ],
        ),
        LubricationEntry(
          id: 'mazani_rozvodovka',
          title: 'Rozvodovka',
          location: 'Rozvodovka a výstupy kardanů',
          icon: Icons.alt_route_outlined,
          mapView: LubricationMapView.underbody,
          hotspotX: 0.50,
          hotspotY: 0.46,
          lubricant: 'SAE 90 bez EP/hypoidních aditiv, stejně jako převodovka T-84',
          interval: 'Pravidelně při servisní kontrole podvozku',
          source: 'War Department Lubrication Guide No. 501',
          beginnerInstructions: [
            'Očisti okolí kontrolní zátky rozvodovky, aby se dovnitř nedostal prach ani staré bláto.',
            'Povol zátku a ověř hladinu oleje u spodní hrany kontrolního otvoru.',
            'Současně zkontroluj, zda nejsou mastné výstupy ke kardanům nebo těsnění hřídelí.',
          ],
          checkpoints: [
            'Do rozvodovky Dana 18 nedávej 85W-140 hypoid, ten patří hlavně do diferenciálů.',
            'Rozvodovka nesmí být čerstvě zamaštěná od nového úniku.',
            'Páky pohonu musí po kontrole chodit jistě a bez drhnutí.',
          ],
          tasks: [
            'Očistit zátku a okolí skříně',
            'Zkontrolovat hladinu oleje',
            'Prověřit těsnění výstupů ke kardanům',
          ],
        ),
        LubricationEntry(
          id: 'mazani_pera',
          title: 'Pera a oka listových per',
          location: 'Přední a zadní oka listových per a jejich čepy',
          icon: Icons.linear_scale_outlined,
          mapView: LubricationMapView.side,
          hotspotX: 0.18,
          hotspotY: 0.66,
          lubricant: 'Víceúčelové lithiové mazivo NLGI 2 až 3; v české praxi lze použít LV 2-3',
          interval: 'Podle mazacího plánu a po jízdě v blátě',
          source: 'War Department Lubrication Guide No. 501',
          beginnerInstructions: [
            'Najdi maznice na čepech a okách listových per a nejprve je očisti od zaschlého bláta.',
            'Mazací lis nasaď rovně a pomalu tlač tuk, dokud se neobjeví čerstvé mazivo.',
            'Stejný postup zopakuj na druhé straně vozu i na zadních perech.',
          ],
          checkpoints: [
            'Mazivo musí jít dovnitř bez velkého odporu.',
            'Po namazání nesmí být maznice ucpané ani poškozené.',
          ],
          tasks: [
            'Očistit maznice na perech',
            'Promazat přední i zadní oka per',
            'Zkontrolovat stav čepů a pouzder',
          ],
        ),
      ],
      pdfManuals: const [],
      manuals: [
        ManualSection(
          title: 'TM 9-803: Kontrola motorového oleje',
          originalHeading: 'Engine Oil Level Check',
          source: 'TM 9-803',
          translation: [
            'Před jízdou zkontroluj hladinu oleje a ujisti se, že vůz stojí na rovném podkladu.',
            'Měrku vytáhni, otři, zasuň zpět a teprve potom odečti skutečnou hladinu.',
          ],
          simplifiedSteps: [
            'Nech Jeep několik minut stát na rovině.',
            'Najdi měrku na pravé straně motoru a otři ji čistým hadrem.',
            'Po opětovném zasunutí zkontroluj, zda hladina sahá do pracovního rozsahu.',
          ],
          cautions: [
            'Neodečítej hladinu hned po vypnutí motoru.',
            'Při nízké hladině vždy hledej i příčinu úbytku oleje.',
          ],
        ),
        ManualSection(
          title: 'TM 9-1803B: Mazání převodovky',
          originalHeading: 'Transmission Lubrication',
          source: 'TM 9-1803B',
          translation: [
            'Převodovka musí být plněna pouze po spodní hranu kontrolního otvoru.',
            'Před otevřením je nutné odstranit bláto a nečistoty z okolí zátky.',
          ],
          simplifiedSteps: [
            'Nejprve převodovku očisti zvenku, aby se dovnitř nic nedostalo.',
            'Povol kontrolní zátku a zkontroluj, zda olej sahá k hraně otvoru.',
            'Doplňuj pomalu a po uzavření zkus krátkou testovací jízdu.',
          ],
          cautions: [
            'Nepřeplňuj skříň nad doporučenou úroveň.',
            'Pokud je olej mléčný nebo plný kovových částic, nestačí jen dolití.',
          ],
        ),
      ],
      guides: [
        GuideNote(
          title: 'Jak pracovat s historickým manuálem',
          summary:
              'Původní armádní manuály jsou přesné, ale často stručné. V aplikaci jsou přepsané do současné češtiny tak, aby laik věděl, co očistit, co povolit a co po montáži zkontrolovat.',
          source: 'TM 9-803 / TM 9-1803B',
        ),
        GuideNote(
          title: 'Kaiser Willys jako praktický zdroj',
          summary:
              'Kaiser Willys dobře poslouží pro orientaci v mazivech, základních specifikacích a běžné údržbě. Hodí se jako rychlá pomůcka, když si potřebuješ ověřit servisní logiku.',
          source: 'Kaiser Willys',
        ),
        GuideNote(
          title: 'Poznámky renovátorů z G503',
          summary:
              'Fórum G503 a příspěvky Greendot319 pomáhají hlavně tam, kde je potřeba praktická zkušenost z rozebírání a opětovného skládání historických dílů.',
          source: 'G503 / Greendot319',
        ),
      ],
    );
  }

  JeepData normalized() {
    final sample = JeepData.sample();

    final defaultCategories = {
      for (final category in defaultServiceCategories()) category.id: category,
    };
    final existingCategories = {
      for (final category in serviceCategories) category.id: category,
    };

    serviceCategories = defaultCategories.values.map((defaultCategory) {
      final existingCategory = existingCategories[defaultCategory.id];
      if (existingCategory == null) {
        return defaultCategory;
      }

      final existingSections = {
        for (final section in existingCategory.sections) section.title: section,
      };

      return ServiceCategory(
        id: defaultCategory.id,
        title: defaultCategory.title,
        description: defaultCategory.description,
        icon: defaultCategory.icon,
        sections: defaultCategory.sections.map((defaultSection) {
          final existingSection = existingSections[defaultSection.title];
          if (existingSection == null) {
            return defaultSection;
          }
          return ServiceSection(
            title: defaultSection.title,
            summary: defaultSection.summary,
            source: defaultSection.source,
            steps: defaultSection.steps,
            checkpoints: defaultSection.checkpoints,
            completed: existingSection.completed,
            lastServiceDate: existingSection.lastServiceDate,
          );
        }).toList(),
      );
    }).toList();

    if (manuals.isEmpty) {
      manuals = sample.manuals;
    }

    pdfManuals = [
      for (final manual in pdfManuals)
        if (manual.filePath.trim().isNotEmpty) manual,
    ];

    final sampleLubrication = {
      for (final entry in sample.lubricationEntries) entry.id: entry,
    };

    lubricationEntries = lubricationEntries.map((entry) {
      final fallback = sampleLubrication[entry.id];
      if (fallback == null) {
        if (entry.taskStates.length != entry.tasks.length) {
          entry.taskStates = List<bool>.filled(entry.tasks.length, false);
        }
        return entry;
      }

      if (entry.tasks.isEmpty) {
        entry.tasks.addAll(fallback.tasks);
      }
      if (entry.taskStates.length != entry.tasks.length) {
        entry.taskStates = List<bool>.filled(entry.tasks.length, false);
      }
      return LubricationEntry(
        id: entry.id,
        title: entry.title,
        location: entry.location,
        icon: entry.icon,
        mapView: entry.mapView,
        hotspotX: entry.hotspotX == 0.5 ? fallback.hotspotX : entry.hotspotX,
        hotspotY: entry.hotspotY == 0.5 ? fallback.hotspotY : entry.hotspotY,
        lubricant: fallback.lubricant,
        interval: fallback.interval,
        source: fallback.source,
        beginnerInstructions: fallback.beginnerInstructions,
        checkpoints: fallback.checkpoints,
        tasks: fallback.tasks,
        taskStates: entry.taskStates,
        lastServiceDate: entry.lastServiceDate,
      );
    }).toList();

    return this;
  }

  Map<String, dynamic> toMap() {
    return {
      'profile': profile.toMap(),
      'serviceCategories': serviceCategories.map((item) => item.toMap()).toList(),
      'lubricationEntries': lubricationEntries.map((item) => item.toMap()).toList(),
      'pdfManuals': pdfManuals.map((item) => item.toMap()).toList(),
      'manuals': manuals.map((item) => item.toMap()).toList(),
      'guides': guides.map((item) => item.toMap()).toList(),
    };
  }

  factory JeepData.fromMap(Map<String, dynamic> map) {
    return JeepData(
      profile: JeepProfile.fromMap(map['profile'] as Map<String, dynamic>),
      serviceCategories: (map['serviceCategories'] as List<dynamic>? ?? const [])
          .map((item) => ServiceCategory.fromMap(item as Map<String, dynamic>))
          .toList(),
      lubricationEntries: (map['lubricationEntries'] as List<dynamic>? ?? const [])
          .map((item) => LubricationEntry.fromMap(item as Map<String, dynamic>))
          .toList(),
      pdfManuals: (map['pdfManuals'] as List<dynamic>? ?? const [])
          .map((item) => PdfManual.fromMap(item as Map<String, dynamic>))
          .toList(),
      manuals: (map['manuals'] as List<dynamic>? ?? const [])
          .map((item) => ManualSection.fromMap(item as Map<String, dynamic>))
          .toList(),
      guides: (map['guides'] as List<dynamic>? ?? const [])
          .map((item) => GuideNote.fromMap(item as Map<String, dynamic>))
          .toList(),
    ).normalized();
  }
}

class JeepProfile {
  JeepProfile({
    required this.imagePath,
    required this.serviceHistory,
    required this.origin,
    required this.year,
    required this.chassisNumber,
    required this.engineNumber,
    required this.hoodNumber,
    required this.lastService,
  });

  String imagePath;
  String serviceHistory;
  String origin;
  String year;
  String chassisNumber;
  String engineNumber;
  String hoodNumber;
  String lastService;

  factory JeepProfile.empty() {
    return JeepProfile(
      imagePath: '',
      serviceHistory: '',
      origin: '',
      year: '',
      chassisNumber: '',
      engineNumber: '',
      hoodNumber: '20516267',
      lastService: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'serviceHistory': serviceHistory,
      'origin': origin,
      'year': year,
      'chassisNumber': chassisNumber,
      'engineNumber': engineNumber,
      'hoodNumber': hoodNumber,
      'lastService': lastService,
    };
  }

  factory JeepProfile.fromMap(Map<String, dynamic> map) {
    return JeepProfile(
      imagePath: map['imagePath'] as String? ?? '',
      serviceHistory: map['serviceHistory'] as String? ?? '',
      origin: map['origin'] as String? ?? '',
      year: map['year'] as String? ?? '',
      chassisNumber: map['chassisNumber'] as String? ?? '',
      engineNumber: map['engineNumber'] as String? ?? '',
      hoodNumber: map['hoodNumber'] as String? ?? '20516267',
      lastService: map['lastService'] as String? ?? '',
    );
  }
}

class ServiceCategory {
  ServiceCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.sections,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<ServiceSection> sections;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon.codePoint,
      'sections': sections.map((item) => item.toMap()).toList(),
    };
  }

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: IconData(
        map['icon'] as int? ?? Icons.build.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      sections: (map['sections'] as List<dynamic>? ?? const [])
          .map((item) => ServiceSection.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ServiceSection {
  ServiceSection({
    required this.title,
    required this.summary,
    required this.source,
    required this.steps,
    required this.checkpoints,
    this.completed = false,
    this.lastServiceDate = '',
  });

  String title;
  String summary;
  String source;
  List<String> steps;
  List<String> checkpoints;
  bool completed;
  String lastServiceDate;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'source': source,
      'steps': steps,
      'checkpoints': checkpoints,
      'completed': completed,
      'lastServiceDate': lastServiceDate,
    };
  }

  factory ServiceSection.fromMap(Map<String, dynamic> map) {
    return ServiceSection(
      title: map['title'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      source: map['source'] as String? ?? '',
      steps: List<String>.from(map['steps'] as List<dynamic>? ?? const []),
      checkpoints:
          List<String>.from(map['checkpoints'] as List<dynamic>? ?? const []),
      completed: map['completed'] as bool? ?? false,
      lastServiceDate: map['lastServiceDate'] as String? ?? '',
    );
  }
}

class LubricationEntry {
  LubricationEntry({
    required this.id,
    required this.title,
    required this.location,
    required this.icon,
    required this.mapView,
    required this.hotspotX,
    required this.hotspotY,
    required this.lubricant,
    required this.interval,
    required this.source,
    required this.beginnerInstructions,
    required this.checkpoints,
    required this.tasks,
    this.lastServiceDate = '',
    List<bool>? taskStates,
  }) : taskStates = taskStates ?? List<bool>.filled(tasks.length, false);

  final String id;
  final String title;
  final String location;
  final IconData icon;
  final LubricationMapView mapView;
  final double hotspotX;
  final double hotspotY;
  final String lubricant;
  final String interval;
  final String source;
  final List<String> beginnerInstructions;
  final List<String> checkpoints;
  final List<String> tasks;
  String lastServiceDate;
  List<bool> taskStates;

  String get detailAssetPath {
    switch (mapView) {
      case LubricationMapView.side:
        return 'assets/images/front_axle.jpg';
      case LubricationMapView.underbody:
        if (id == 'mazani_predni_diferencial') {
          return 'assets/images/front_axle.jpg';
        }
        if (id == 'mazani_rozvodovka') {
          return 'assets/images/podvozek_mazaci_plan.jpg';
        }
        if (id == 'mazani_pera') {
          return 'assets/images/rear_diff_real.jpg';
        }
        return 'assets/images/podvozek_mazaci_plan.jpg';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'icon': icon.codePoint,
      'mapView': mapView.name,
      'hotspotX': hotspotX,
      'hotspotY': hotspotY,
      'lubricant': lubricant,
      'interval': interval,
      'source': source,
      'beginnerInstructions': beginnerInstructions,
      'checkpoints': checkpoints,
      'tasks': tasks,
      'taskStates': taskStates,
      'lastServiceDate': lastServiceDate,
    };
  }

  factory LubricationEntry.fromMap(Map<String, dynamic> map) {
    return LubricationEntry(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      location: map['location'] as String? ?? '',
      icon: IconData(
        map['icon'] as int? ?? Icons.opacity.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      mapView: LubricationMapView.values.firstWhere(
        (value) => value.name == (map['mapView'] as String? ?? 'underbody'),
        orElse: () => LubricationMapView.underbody,
      ),
      hotspotX: (map['hotspotX'] as num?)?.toDouble() ?? 0.5,
      hotspotY: (map['hotspotY'] as num?)?.toDouble() ?? 0.5,
      lubricant: map['lubricant'] as String? ?? '',
      interval: map['interval'] as String? ?? '',
      source: map['source'] as String? ?? '',
      beginnerInstructions: List<String>.from(
        map['beginnerInstructions'] as List<dynamic>? ?? const [],
      ),
      checkpoints:
          List<String>.from(map['checkpoints'] as List<dynamic>? ?? const []),
      tasks: List<String>.from(map['tasks'] as List<dynamic>? ?? const []),
      lastServiceDate: map['lastServiceDate'] as String? ?? '',
      taskStates: List<bool>.from(map['taskStates'] as List<dynamic>? ?? const []),
    );
  }
}

enum LubricationMapView {
  side,
  underbody,
}

class PdfManual {
  const PdfManual({
    required this.title,
    required this.filePath,
    required this.source,
  });

  final String title;
  final String filePath;
  final String source;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'filePath': filePath,
      'source': source,
    };
  }

  factory PdfManual.fromMap(Map<String, dynamic> map) {
    return PdfManual(
      title: map['title'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      source: map['source'] as String? ?? 'Lokální PDF manuál',
    );
  }
}

class ManualSection {
  ManualSection({
    required this.title,
    required this.originalHeading,
    required this.source,
    required this.translation,
    required this.simplifiedSteps,
    required this.cautions,
  });

  final String title;
  final String originalHeading;
  final String source;
  final List<String> translation;
  final List<String> simplifiedSteps;
  final List<String> cautions;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'originalHeading': originalHeading,
      'source': source,
      'translation': translation,
      'simplifiedSteps': simplifiedSteps,
      'cautions': cautions,
    };
  }

  factory ManualSection.fromMap(Map<String, dynamic> map) {
    return ManualSection(
      title: map['title'] as String? ?? '',
      originalHeading: map['originalHeading'] as String? ?? '',
      source: map['source'] as String? ?? '',
      translation: List<String>.from(map['translation'] as List<dynamic>? ?? const []),
      simplifiedSteps: List<String>.from(
        map['simplifiedSteps'] as List<dynamic>? ?? const [],
      ),
      cautions: List<String>.from(map['cautions'] as List<dynamic>? ?? const []),
    );
  }
}

class GuideNote {
  GuideNote({
    required this.title,
    required this.summary,
    required this.source,
  });

  final String title;
  final String summary;
  final String source;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'source': source,
    };
  }

  factory GuideNote.fromMap(Map<String, dynamic> map) {
    return GuideNote(
      title: map['title'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      source: map['source'] as String? ?? '',
    );
  }
}



