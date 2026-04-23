import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import '../../services/supabase_service.dart';
import 'dart:typed_data';
import '../../models/part.dart';

class PartEditScreen extends StatefulWidget {
  final Part? existing;
  const PartEditScreen({super.key, this.existing});

  @override
  State<PartEditScreen> createState() => _PartEditScreenState();
}

class _PartEditScreenState extends State<PartEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = ValueNotifier<String>('Engine');
  final _price = TextEditingController();
  final _qty = TextEditingController();
  final _low = TextEditingController(text: '5');
  bool _saving = false;
  String? _error;
  XFile? _pickedImage;
  Uint8List? _pickedBytes;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _name.text = p.name;
      _category.value = p.category;
      _price.text = p.price.toString();
      _qty.text = p.quantity.toString();
      _low.text = p.lowStockThreshold.toString();
      _imageUrl = p.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() {
        _pickedImage = x;
        _pickedBytes = bytes;
      });
  // Log pick event
  print('[ImagePicker] Picked: ${x.name} size=${bytes.lengthInBytes}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      // Upload image to Supabase Storage if picked
      if (_pickedImage != null) {
        final id = widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        final path = 'parts/$id.jpg';
  print('[Upload] Starting upload for part id=$id path=$path');
        _imageUrl = await SupabaseService.uploadImage(
          bytes: _pickedBytes!,
          bucket: 'parts-photos',
          path: path,
          contentType: 'image/jpeg',
        );
  print('[Upload] Completed. Image URL: $_imageUrl');
      }
      final data = {
        'name': _name.text.trim(),
        'category': _category.value,
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'quantity': int.tryParse(_qty.text.trim()) ?? 0,
        'lowStockThreshold': int.tryParse(_low.text.trim()) ?? 0,
        'qrData': widget.existing?.qrData ?? '',
        'imageUrl': _imageUrl ?? widget.existing?.imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      final col = FirebaseFirestore.instance.collection('parts');
      if (widget.existing == null) {
        final added = await col.add(data);
        await col.doc(added.id).update({'qrData': added.id});
      } else {
        await col.doc(widget.existing!.id).update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = e.toString(); });
    }
    setState(() { _saving = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Part' : 'Edit Part')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
        GestureDetector(
                onTap: _saving ? null : _pickImage,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
          image: ((_pickedBytes != null) || (_imageUrl?.isNotEmpty ?? false))
                        ? DecorationImage(
                            fit: BoxFit.cover,
              image: _pickedBytes != null
                ? MemoryImage(_pickedBytes!)
                    : NetworkImage(_imageUrl!),
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
          child: (_pickedBytes == null && (_imageUrl?.isEmpty ?? true))
                      ? const Text('Tap to upload image')
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Part name'),
                validator: (v) => (v==null||v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: _category,
                builder: (context, value, _) => DropdownButtonFormField<String>(
                  value: value,
                  items: const [
                    DropdownMenuItem(value: 'Engine', child: Text('Engine')),
                    DropdownMenuItem(value: 'Electrical', child: Text('Electrical')),
                    DropdownMenuItem(value: 'Body', child: Text('Body')),
                  ],
                  onChanged: (v) => _category.value = v ?? 'Engine',
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Price (Rs)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null) return 'Enter number';
                  if (val < 0) return 'Must be non-negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null) return 'Enter integer';
                  if (val < 0) return 'Must be non-negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _low,
                decoration: const InputDecoration(labelText: 'Low stock threshold'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = int.tryParse(v ?? '');
                  if (val == null) return 'Enter integer';
                  if (val < 0) return 'Must be non-negative';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(height:16,width:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
