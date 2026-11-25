
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auction_service.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final AuctionService _auctionService = AuctionService();

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _reservePriceController = TextEditingController();
  final _incrementController = TextEditingController();

  final List<String> _categories = [
    'Vehicles',
    'Heavy Machinery',
    'Land & Property',
    'Electronics',
    'Furniture',
    'Other',
  ];

  String? _selectedCategory;

  DateTime? _startTime;
  DateTime? _endTime;

  final List<XFile> _images = [];
  int _primaryImageIndex = 0;

  bool _isSubmitting = false;

  // --------------------------------------------------
  // IMAGE PICKER
  // --------------------------------------------------

  Future<void> _pickImages() async {
    try {
      final pickedImages =
          await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (pickedImages.isEmpty) return;

      setState(() {
        for (final image in pickedImages) {
          final alreadyAdded = _images.any(
            (existing) => existing.path == image.path,
          );

          if (!alreadyAdded) {
            _images.add(image);
          }
        }
      });
    } catch (e) {
      _showMessage('Unable to select images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);

      if (_images.isEmpty) {
        _primaryImageIndex = 0;
      } else if (_primaryImageIndex >= _images.length) {
        _primaryImageIndex = 0;
      } else if (index < _primaryImageIndex) {
        _primaryImageIndex--;
      }
    });
  }

  void _setPrimaryImage(int index) {
    setState(() {
      _primaryImageIndex = index;
    });
  }

  // --------------------------------------------------
  // DATE AND TIME PICKERS
  // --------------------------------------------------

  Future<DateTime?> _pickDateTime({
    required DateTime initialDate,
    required DateTime firstDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        initialDate,
      ),
    );

    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();

    final selected = await _pickDateTime(
      initialDate: _startTime ?? now,
      firstDate: now,
    );

    if (selected == null) return;

    setState(() {
      _startTime = selected;

      if (_endTime != null &&
          !_endTime!.isAfter(selected)) {
        _endTime = null;
      }
    });
  }

  Future<void> _selectEndTime() async {
    final now = DateTime.now();

    final selected = await _pickDateTime(
      initialDate: _endTime ??
          (_startTime ??
              now.add(const Duration(days: 1))),
      firstDate: _startTime ?? now,
    );

    if (selected == null) return;

    if (_startTime != null &&
        !selected.isAfter(_startTime!)) {
      _showMessage(
        'End time must be after start time.',
      );
      return;
    }

    setState(() {
      _endTime = selected;
    });
  }

  // --------------------------------------------------
  // FORM SUBMISSION
  // --------------------------------------------------

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      _showMessage('Please select a category.');
      return;
    }

    if (_images.isEmpty) {
      _showMessage('Please add at least one asset image.');
      return;
    }

    if (_startTime == null || _endTime == null) {
      _showMessage('Please select auction start and end times.');
      return;
    }

    if (!_endTime!.isAfter(_startTime!)) {
      _showMessage('End time must be after start time.');
      return;
    }

    final startingPrice =
        double.tryParse(_startingPriceController.text);

    final reservePrice =
        double.tryParse(_reservePriceController.text);

    final increment =
        double.tryParse(_incrementController.text);

    if (startingPrice == null ||
        reservePrice == null ||
        increment == null) {
      _showMessage('Enter valid pricing information.');
      return;
    }

    if (startingPrice <= 0 ||
        reservePrice < startingPrice ||
        increment <= 0) {
      _showMessage(
        'Check your prices. Reserve price must be at least the starting price.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final imagePaths = _images
          .map((image) => image.path)
          .toList();

      await _auctionService.createAsset(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        startingPrice: startingPrice,
        reservePrice: reservePrice,
        minIncrement: increment,
        startTime: _startTime!,
        endTime: _endTime!,
        images: imagePaths,
      );

      if (!mounted) return;

      _showMessage('Listing created successfully.');

      _formKey.currentState?.reset();
      setState(() {
        _images.clear();
        _selectedCategory = null;
        _startTime = null;
        _endTime = null;
      });
    } catch (e) {
      _showMessage('Unable to create listing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Select date and time';

    final local = date.toLocal();

    final dateText =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';

    final hour = local.hour % 12 == 0
        ? 12
        : local.hour % 12;

    final minute =
        local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$dateText  $hour:$minute $period';
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _dateSelector({
    required String title,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDateTime(value),
                    style: TextStyle(
                      color: value == null
                          ? Colors.grey
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // IMAGE SECTION
  // --------------------------------------------------

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Asset Images',
          'Add clear photos of the asset. Select one as the primary image.',
        ),

        const SizedBox(height: 14),

        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 28,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                style: BorderStyle.solid,
              ),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.05),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add asset photos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose multiple images from your device',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_images.isNotEmpty) ...[
          const SizedBox(height: 16),

          Text(
            '${_images.length} image(s) selected',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _images.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final isPrimary =
                  index == _primaryImageIndex;

              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(
                            _images[index].path,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_images[index].path),
                            fit: BoxFit.cover,
                          ),
                  ),

                  if (isPrimary)
                    Positioned(
                      left: 5,
                      bottom: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRIMARY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 4,
                    left: 4,
                    child: InkWell(
                      onTap: () => _setPrimaryImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? Colors.green
                              : Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Listing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle(
              'List your asset',
              'Provide accurate information to attract bidders.',
            ),

            const SizedBox(height: 24),

            // ASSET INFORMATION

            const Text(
              'Asset information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                'Asset title',
                hint: 'e.g. Toyota Land Cruiser V8',
                icon: Icons.inventory_2_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the asset title';
                }

                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: _inputDecoration(
                'Description',
                hint: 'Describe the asset, its condition and features...',
                icon: Icons.description_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an asset description';
                }

                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: _inputDecoration(
                'Asset category',
                icon: Icons.category_outlined,
              ),
              hint: const Text('Select a category'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Select an asset category';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // PRICING

            const Text(
              'Auction pricing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _startingPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                'Starting price (UGX)',
                hint: 'Enter starting price',
                icon: Icons.payments_outlined,
              ),
              validator: _validatePositiveNumber,
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _reservePriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                'Reserve price (UGX)',
                hint: 'Enter minimum acceptable price',
                icon: Icons.lock_outline,
              ),
              validator: (value) {
                final error = _validatePositiveNumber(value);
                if (error != null) return error;

                final starting = double.tryParse(
                  _startingPriceController.text,
                );
                final reserve = double.tryParse(value ?? '');

                if (starting != null &&
                    reserve != null &&
                    reserve < starting) {
                  return 'Reserve must be at least the starting price';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _incrementController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                'Minimum bid increment (UGX)',
                hint: 'Enter minimum increment',
                icon: Icons.trending_up,
              ),
              validator: _validatePositiveNumber,
            ),

            const SizedBox(height: 28),

            // AUCTION SCHEDULE

            const Text(
              'Auction schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            _dateSelector(
              title: 'Auction start',
              value: _startTime,
              onTap: _selectStartTime,
              icon: Icons.play_circle_outline,
            ),

            const SizedBox(height: 12),

            _dateSelector(
              title: 'Auction end',
              value: _endTime,
              onTap: _selectEndTime,
              icon: Icons.event_available_outlined,
            ),

            const SizedBox(height: 28),

            // IMAGES

            _buildImageSection(),

            const SizedBox(height: 32),

            // SUBMIT

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : _submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Create Listing',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final number = double.tryParse(value);

    if (number == null || !number.isFinite || number <= 0) {
      return 'Enter a valid amount greater than zero';
    }

    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _reservePriceController.dispose();
    _incrementController.dispose();

    super.dispose();
  }
}
