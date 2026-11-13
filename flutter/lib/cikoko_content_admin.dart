import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'cikoko_v6_showcase.dart';

/// Admin-only native editor for shared website + app content.
class CikokoContentAdmin extends StatefulWidget {
  final CikokoApi api;
  final String contentType;
  final VoidCallback? onPublished;
  const CikokoContentAdmin({
    super.key, required this.api, required this.contentType,
    this.onPublished,
  });
  @override State<CikokoContentAdmin> createState() => _CikokoContentAdminState();
}

class _CikokoContentAdminState extends State<CikokoContentAdmin> {
  bool loading = true;
  String? error;
  List<Map<String,dynamic>> items = [];
  String get title => const {
    'berita':'Berita & Informasi',
    'pengumuman':'Pengumuman',
    'galeri':'Galeri Kegiatan',
    'layanan':'Detail Layanan Website',
  }[widget.contentType] ?? 'Konten';
  @override void initState() { super.initState(); refresh(); }
  Future<void> refresh() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final data = await widget.api.call('cms_content_list');
      final rows = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((r) => Map<String,dynamic>.from(r))
        .where((r) => r['type'] == widget.contentType)
        .toList();
      if (mounted) setState(() => items = rows);
    } catch (e) {
      if (mounted) setState(() => error =
          'Tidak dapat mengambil konten website: ' + e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  Future<void> edit([Map<String,dynamic>? item]) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(item == null
          ? 'Tambah ' + title : 'Edit ' + title)),
        body: CikokoContentForm(api: widget.api,
          type: widget.contentType, item: item,
          onPublished: () {
            widget.onPublished?.call();
            refresh();
          }),
      ),
    ));
    if (mounted) refresh();
  }
  Future<void> remove(Map<String,dynamic> item) async {
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus konten?'),
        content: Text('Hapus "' + (item['title'] ?? '').toString() +
          '" dari website dan aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus')),
        ],
      ));
    if (ok != true || !mounted) return;
    try {
      await widget.api.call('cms_content_delete',
        body: {'id': (item['id'] ?? '').toString()});
      widget.onPublished?.call();
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menghapus: ' + e.toString())));
    }
  }
  @override Widget build(BuildContext context) => ListView(
    key: Key('native_cms_content_' + widget.contentType),
    padding: const EdgeInsets.all(14),
    children: [
      V6PageHeader(title: title,
        description: 'Tambah, edit, dan hapus konten langsung dari aplikasi.',
        icon: Icons.edit_note_outlined),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () => edit(),
        icon: const Icon(Icons.add), label: Text('Tambah ' + title)),
      const SizedBox(height: 12),
      if (loading) const LinearProgressIndicator(),
      if (error != null) Text(error!,
        style: const TextStyle(color: Colors.red)),
      if (!loading && error == null && items.isEmpty)
        const V6Panel(child: Text('Belum ada konten untuk bagian ini.')),
      for (final item in items)
        Card(child: ListTile(
          key: Key('cms_item_' + (item['id'] ?? '').toString()),
          leading: const Icon(Icons.article_outlined,color: V6.blue),
          title: Text((item['title'] ?? 'Tanpa judul').toString(),
            maxLines: 2),
          subtitle: Text((item['created_at'] ?? '').toString()),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') edit(item);
              if (action == 'delete') remove(item);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
          onTap: () => edit(item),
        )),
      TextButton.icon(onPressed: refresh,
        icon: const Icon(Icons.refresh),
        label: const Text('Muat Ulang')),
    ],
  );
}

class CikokoContentForm extends StatefulWidget {
  final CikokoApi api;
  final String type;
  final Map<String,dynamic>? item;
  final VoidCallback? onPublished;
  const CikokoContentForm({
    super.key, required this.api, required this.type, this.item,
    this.onPublished,
  });
  @override State<CikokoContentForm> createState() => _CikokoContentFormState();
}

class _CikokoContentFormState extends State<CikokoContentForm> {
  late final TextEditingController title, body, link;
  String imagePath = '';
  String? pickedPath, error;
  bool saving = false;
  @override void initState() {
    super.initState();
    title = TextEditingController(text:
      (widget.item?['title'] ?? '').toString());
    // Server content may contain HTML from the old website editor.
    final oldBody = (widget.item?['body'] ?? '').toString()
      .replaceAll(RegExp(r'<br\s*/?>',caseSensitive:false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
    body = TextEditingController(text: oldBody);
    link = TextEditingController(text:
      (widget.item?['link'] ?? '').toString());
  }
  @override void dispose() {
    title.dispose(); body.dispose(); link.dispose();
    super.dispose();
  }
  Future<void> pick(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source, maxWidth: 2048, imageQuality: 80);
    if (photo != null && mounted) setState(() => pickedPath = photo.path);
  }
  Future<void> save() async {
    if (saving) return;
    if (title.text.trim().length < 3 || body.text.trim().length < 3) {
      setState(() => error = 'Judul dan isi minimal 3 karakter.');
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      if (pickedPath != null) {
        final uploaded = await widget.api.upload(
          'cms_media_upload', {}, {'photo': [pickedPath!]});
        imagePath = (uploaded['path'] ?? '').toString();
        if (!imagePath.startsWith('assets/images/')) {
          throw ApiError('Upload foto belum berhasil.');
        }
      }
      await widget.api.call('cms_content_save', body: {
        'id': (widget.item?['id'] ?? '').toString(),
        'type': widget.type,
        'title': title.text.trim(),
        'body': body.text.trim(),
        'link': link.text.trim(),
        'image': imagePath,
      });
      widget.onPublished?.call();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => error = 'Gagal menyimpan: ' + e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  @override Widget build(BuildContext context) => ListView(
    key: const Key('native_cms_content_form'),
    padding: const EdgeInsets.all(16),
    children: [
      TextField(controller: title, maxLength: 200,
        decoration: const InputDecoration(labelText: 'Judul')),
      const SizedBox(height: 12),
      TextField(controller: body, minLines: 5, maxLines: 10,
        maxLength: 12000,
        decoration: const InputDecoration(labelText: 'Isi / Deskripsi')),
      const SizedBox(height: 12),
      TextField(controller: link, keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Tautan HTTPS (opsional)')),
      const SizedBox(height: 10),
      const Text('Foto konten (opsional)',
        style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: [
        OutlinedButton.icon(onPressed: saving ? null :
          () => pick(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Galeri')),
        OutlinedButton.icon(onPressed: saving ? null :
          () => pick(ImageSource.camera),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Kamera')),
      ]),
      if (pickedPath != null)
        Text('Foto baru dipilih (akan diunggah ketika disimpan).',
          style: const TextStyle(color: Colors.green)),
      if (widget.item?['image'] != null && pickedPath == null)
        Text('Foto sebelumnya tetap dipertahankan.',
          style: const TextStyle(color: V6.secondary)),
      if (error != null) Text(error!,
        style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 18),
      FilledButton.icon(
        key: const Key('cms_content_save'),
        onPressed: saving ? null : save,
        icon: const Icon(Icons.save_outlined),
        label: Text(saving ? 'Menyimpan...' : 'Simpan ke Website & Aplikasi'),
      ),
    ],
  );
}
