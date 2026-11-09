import 'package:flutter/material.dart';
import 'package:wakeway/features/destinations/viewmodels/destination_view_model.dart';
import 'package:wakeway/features/map/models/wake_destination.dart';
import 'package:wakeway/shared/ui.dart';

class SavedDestinationsScreen extends StatefulWidget {
  const SavedDestinationsScreen({
    super.key,
    required this.viewModel,
    required this.onAdd,
    required this.onSelect,
  });

  final DestinationViewModel viewModel;
  final VoidCallback onAdd;
  final ValueChanged<WakeDestination> onSelect;

  @override
  State<SavedDestinationsScreen> createState() =>
      _SavedDestinationsScreenState();
}

class _SavedDestinationsScreenState extends State<SavedDestinationsScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _rename(WakeDestination place) async {
    final editor = TextEditingController(text: place.name);
    
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename destination'),
        content: TextField(
          controller: editor,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, editor.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
     if (!mounted) return;
    if (name != null) {
      final renamed = await widget.viewModel.renameDestination(place, name);
      if (!renamed) _showError();
    }
  }

  Future<void> _remove(WakeDestination place) async {
    final removed = await widget.viewModel.removeDestination(place);
    if (!removed) _showError();
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.viewModel.errorMessage ?? 'Could not update destinations.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.viewModel,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Saved destinations')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your familiar places',
                style: TextStyle(
                  color: WakeColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.45,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your saved stops are synced to your WakeWay account.',
                style: TextStyle(color: WakeColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Add destination',
                icon: Icons.add_location_alt_rounded,
                onPressed:
                    widget.viewModel.isLoading || widget.viewModel.isSaving
                    ? null
                    : widget.onAdd,
              ),
              const SizedBox(height: 17),
              if (widget.viewModel.errorMessage != null)
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.viewModel.errorMessage!),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: widget.viewModel.initialize,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              if (widget.viewModel.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (widget.viewModel.destinations.isEmpty &&
                  widget.viewModel.errorMessage == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No saved destinations yet.'),
                  ),
                ),
              ...widget.viewModel.destinations.map(
                (place) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        IconTile(
                          icon: place.name.toLowerCase().contains('home')
                              ? Icons.home_rounded
                              : Icons.place_rounded,
                          color: WakeColors.blue,
                          background: WakeColors.blueSoft,
                          size: 45,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: InkWell(
                            onTap: () => widget.onSelect(place),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: const TextStyle(
                                    color: WakeColors.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  place.address,
                                  style: const TextStyle(
                                    color: WakeColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    color: WakeColors.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: WakeColors.muted,
                          ),
                          onSelected: (action) async {
                            if (action == 'delete') {
                              await _remove(place);
                            } else if (action == 'edit') {
                              await _rename(place);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Rename')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Saved destinations are available on your signed-in devices.',
                  style: TextStyle(color: WakeColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
