import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

/// Updates the same cikoko_home_slides source rendered by cpanel/index.php.
class CikokoHomeSlidesEditor extends StatefulWidget {
  final CikokoApi api;
  final VoidCallback? onPublished;
  const CikokoHomeSlidesEditor({
    super.key, required this.api, this.onPublished,
  });

  @override
  State<CikokoHomeSlidesEditor> createState() => _CikokoHomeSlidesEditorState();
}

class _CikokoHomeSlidesEditorState extends State<CikokoHomeSlidesEditor> {
  List<String> photos = [];
  bool loading = true, uploading = false, saving = false;
  String? error;
  String? notice;

  @override
  void initState() {
    super.initState();
    load();
  }

  static final _photoName = RegExp(r'^[a-f0-9]{40}\.(jpg|png|webp)$');

  String photoUrl(String name) => Uri.https(
    'datawebs.my.id',
    '/mobile-api/index.php',
    {'action': 'home_slide_photo', 'name': name},
  ).toString();

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final result = await widget.api.call('home_slides');
      final values = (result['slides'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((row) => (row['name'] ?? '').toString())
          .where((name) => _photoName.hasMatch(name))
          .take(5).toList();
      if (mounted) setState(() { photos = values; notice = null; });
    } catch (e) {
      if (mounted) setState(() {
        error = 'Foto header belum bisa dimuat: ' + e.toString();
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> addPhoto(ImageSource source) async {
    if (photos.length >= 5 || uploading || saving) return;
    final picked = await ImagePicker().pickImage(
      source: source, imageQuality: 78, maxWidth: 2048,
    );
    if (picked == null || !mounted) return;
    setState(() { uploading = true; error = null; notice = null; });
    try {
      final response = await widget.api.upload(
        'home_slide_upload', {}, {'photo': [picked.path]},
      );
      final name = (response['name'] ?? '').toString();
      if (!_photoName.hasMatch(name)) throw ApiError('Nama foto tidak valid.');
      if (mounted) setState(() => photos.add(name));
    } catch (e) {
      if (mounted) setState(() => error = 'Upload gagal: ' + e.toString());
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> publish() async {
    if (uploading || saving || loading) return;
    setState(() { saving = true; error = null; notice = null; });
    try {
      await widget.api.call('home_slides_save', body: {'slides': photos});
      if (!mounted) return;
      setState(() => notice =
        'Foto header tersimpan. Website dan aplikasi mengambil daftar yang sama.');
      widget.onPublished?.call();
    } catch (e) {
      if (mounted) setState(() => error =
        'Foto belum berhasil diterbitkan: ' + e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      key: const Key('native_home_header_editor'),
      padding: const EdgeInsets.all(14),
      children: [
        const V6PageHeader(
          title: 'Ganti Foto Header',
          description: 'Atur 1–5 foto header untuk website dan Android Cikoko.',
          icon: Icons.photo_library_outlined,
        ),
        const SizedBox(height: 9),
        const V6Panel(child: Text(
          'Perubahan belum terbit sebelum menekan Simpan. '
          'Urutan pertama menjadi foto utama di Android. '
          'Website menampilkan slideshow dari daftar yang sama.',
          style: TextStyle(fontSize: 12),
        )),
        const SizedBox(height: 12),
        if (error != null) Text(error!,
          style: const TextStyle(color: Colors.red)),
        if (notice != null) Text(notice!,
          style: const TextStyle(color: Colors.green)),
        const SizedBox(height: 12),
        for (var i = 0; i < photos.length; i++)
          Card(child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl(photos[i]),
                  headers: widget.api.authHeaders(),
                  width: 90, height: 70, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(width: 90, height: 70,
                        child: Icon(Icons.broken_image_outlined)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(i == 0
                  ? 'Foto ' + (i + 1).toString() + ' — Utama'
                  : 'Foto ' + (i + 1).toString(),
                style: const TextStyle(fontWeight: FontWeight.w700))),
              IconButton(
                tooltip: 'Naikkan urutan',
                onPressed: i == 0 || saving ? null : () =>
                  setState(() {
                    final value = photos.removeAt(i);
                    photos.insert(i - 1, value);
                  }),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Hapus dari header',
                onPressed: saving ? null : () =>
                  setState(() => photos.removeAt(i)),
                icon: const Icon(Icons.delete_outline),
              ),
            ]),
          )),
        if (photos.isEmpty)
          const V6Panel(child: Text(
            'Belum ada foto header. Tambahkan dari kamera atau galeri.',
          )),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            key: const Key('header_take_camera_photo'),
            onPressed: photos.length >= 5 || uploading || saving
              ? null : () => addPhoto(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Kamera'),
          ),
          OutlinedButton.icon(
            key: const Key('header_choose_gallery_photo'),
            onPressed: photos.length >= 5 || uploading || saving
              ? null : () => addPhoto(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galeri'),
          ),
        ]),
        const SizedBox(height: 10),
        Text(photos.length.toString() + '/5 foto header',
          style: const TextStyle(color: V6.secondary)),
        if (uploading) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('header_publish_button'),
          onPressed: saving || uploading || loading ? null : publish,
          icon: const Icon(Icons.save_outlined),
          label: Text(saving ? 'Menyimpan...' :
            'Simpan dan Sinkronkan dengan Website'),
        ),
        TextButton.icon(
          onPressed: saving || uploading ? null : load,
          icon: const Icon(Icons.refresh),
          label: const Text('Muat Ulang dari Website'),
        ),
      ],
    );
  }
}
