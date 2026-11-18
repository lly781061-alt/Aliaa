// أضف هذه البطاقة داخل قائمة الإعدادات في ملف lib/main.dart:
Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('النسخ الاحتياطي وربط Google Drive', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
        const SizedBox(height: 10),
        Text('حساب جوجل درايف المرتبط: ${store.linkedDriveEmail}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
          icon: const Icon(Icons.cloud),
          label: Text(store.linkedDriveEmail == 'غير متصل' ? 'ربط حساب Google Drive' : 'تغيير أو تبديل حساب Google Drive'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                final emailC = TextEditingController();
                return AlertDialog(
                  title: const Text('ربط حساب Google Drive'),
                  content: TextField(controller: emailC, decoration: const InputDecoration(labelText: 'أدخل بريدك الإلكتروني (Gmail)')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                    ElevatedButton(
                      onPressed: () {
                        if (emailC.text.isNotEmpty) {
                          store.linkedDriveEmail = emailC.text.trim();
                          store.saveData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم ربط الحساب ومزامنة Google Drive بنجاح!')));
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('ربط وحفظ'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
          icon: const Icon(Icons.phone_android),
          label: const Text('حفظ نسخة احتياطية في ذاكرة الهاتف'),
          onPressed: () async {
            String? path = await store.saveLocalBackupFile();
            if (path != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ النسخة في الهاتف بنجاح: $path')));
            }
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
          icon: const Icon(Icons.qr_code),
          label: const Text('مشاركة الباركود للمزامنة الفورية مع الهاتف الثاني'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRBackupScreen(storeData: store))),
        ),
      ],
    ),
  ),
),
