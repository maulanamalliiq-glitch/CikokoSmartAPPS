import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';

/// Reset password using the email stored on the existing Cikoko account.
/// OTP is generated and verified only on the server.
class CikokoForgotPasswordPage extends StatefulWidget {
  final CikokoApi api;
  final String initialUsername;
  const CikokoForgotPasswordPage({
    super.key,
    required this.api,
    this.initialUsername = '',
  });
  @override
  State<CikokoForgotPasswordPage> createState() => _CikokoForgotPasswordState();
}
class _CikokoForgotPasswordState extends State<CikokoForgotPasswordPage> {
  late final TextEditingController username;
  final email=TextEditingController();
  final otp=TextEditingController();
  final password=TextEditingController();
  final confirm=TextEditingController();
  bool busy=false, codeSent=false, showPassword=false, showConfirm=false;
  @override
  void initState(){
    super.initState();
    username=TextEditingController(text:widget.initialUsername);
  }
  @override
  void dispose(){
    username.dispose();email.dispose();otp.dispose();
    password.dispose();confirm.dispose();
    super.dispose();
  }
  void message(Object value){
    if(!mounted)return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text(cikokoFormalMessage(value))));
  }
  Future<void> requestOtp() async{
    if(busy)return;
    final u=username.text.trim(),e=email.text.trim();
    if(u.isEmpty||!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)){
      message('Isi username dan email terdaftar yang valid.');return;
    }
    setState(()=>busy=true);
    try{
      final response=await widget.api.call('password_otp_request',body:{
        'username':u,'email':e,
      });
      if(!mounted)return;
      setState(()=>codeSent=true);
      message(response['message']??'Jika data sesuai, OTP dikirim ke email.');
    }catch(err){message(err);}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> resetPassword() async{
    if(busy)return;
    if(!RegExp(r'^\d{6}$').hasMatch(otp.text.trim())){
      message('Masukkan kode OTP 6 angka.');return;
    }
    if(password.text.length<10||password.text.length>128||
       !RegExp(r'[A-Za-z]').hasMatch(password.text)||
       !RegExp(r'\d').hasMatch(password.text)){
      message('Kata sandi minimal 10 karakter serta memuat huruf dan angka.');return;
    }
    if(password.text!=confirm.text){
      message('Konfirmasi kata sandi tidak sama.');return;
    }
    setState(()=>busy=true);
    try{
      await widget.api.call('password_otp_reset',body:{
        'username':username.text.trim(),'email':email.text.trim(),
        'otp':otp.text.trim(),'new_password':password.text,
        'confirm_password':confirm.text,
      });
      if(!mounted)return;
      Navigator.of(context).pop(true);
    }catch(err){message(err);}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Lupa Kata Sandi')),
    body:SafeArea(child:Center(child:SingleChildScrollView(
      padding:const EdgeInsets.all(20),
      child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),
        child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          const Center(child:Icon(Icons.mark_email_read_outlined,
            size:58,color:Color(0xFF1B60A8))),
          const SizedBox(height:14),
          Text(codeSent?'Verifikasi OTP Email':'Pulihkan Akun Cikoko Smart',
            textAlign:TextAlign.center,
            style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          Text(codeSent
            ?'Masukkan 6 digit kode dari email Anda. Kode berlaku 10 menit dan hanya dapat dipakai sekali.'
            :'Masukkan username dan email yang telah didaftarkan pada akun Anda. Kode OTP akan dikirim ke alamat email tersebut.',
            textAlign:TextAlign.center,
            style:const TextStyle(color:Colors.blueGrey)),
          const SizedBox(height:22),
          TextField(
            controller:username,enabled:!codeSent&&!busy,
            textInputAction:TextInputAction.next,
            decoration:const InputDecoration(
              labelText:'Username',prefixIcon:Icon(Icons.person_outline),
              border:OutlineInputBorder())),
          const SizedBox(height:12),
          TextField(
            controller:email,enabled:!codeSent&&!busy,
            keyboardType:TextInputType.emailAddress,
            textInputAction:TextInputAction.done,
            decoration:const InputDecoration(
              labelText:'Email terdaftar',prefixIcon:Icon(Icons.alternate_email),
              border:OutlineInputBorder())),
          if(codeSent)...[
            const SizedBox(height:16),
            TextField(
              controller:otp,enabled:!busy,
              keyboardType:TextInputType.number,
              textInputAction:TextInputAction.next,
              maxLength:6,
              inputFormatters:[FilteringTextInputFormatter.digitsOnly],
              decoration:const InputDecoration(
                labelText:'Kode OTP 6 digit',prefixIcon:Icon(Icons.password),
                border:OutlineInputBorder())),
            const SizedBox(height:4),
            TextField(
              controller:password,enabled:!busy,
              obscureText:!showPassword,
              decoration:InputDecoration(
                labelText:'Kata sandi baru',prefixIcon:const Icon(Icons.lock_outline),
                border:const OutlineInputBorder(),
                suffixIcon:IconButton(
                  tooltip:showPassword?'Sembunyikan kata sandi':'Lihat kata sandi',
                  onPressed:()=>setState(()=>showPassword=!showPassword),
                  icon:Icon(showPassword?Icons.visibility_off:Icons.visibility)))),
            const SizedBox(height:12),
            TextField(
              controller:confirm,enabled:!busy,
              obscureText:!showConfirm,
              decoration:InputDecoration(
                labelText:'Ulangi kata sandi baru',
                prefixIcon:const Icon(Icons.lock_reset),
                border:const OutlineInputBorder(),
                suffixIcon:IconButton(
                  tooltip:showConfirm?'Sembunyikan kata sandi':'Lihat kata sandi',
                  onPressed:()=>setState(()=>showConfirm=!showConfirm),
                  icon:Icon(showConfirm?Icons.visibility_off:Icons.visibility)))),
            const SizedBox(height:10),
            const Text('Gunakan minimal 10 karakter, huruf dan angka.',
              style:TextStyle(color:Colors.blueGrey,fontSize:12)),
          ],
          const SizedBox(height:22),
          SizedBox(height:48,child:FilledButton.icon(
            onPressed:busy?null:(codeSent?resetPassword:requestOtp),
            icon:busy
              ?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))
              :Icon(codeSent?Icons.check_circle_outline:Icons.send_outlined),
            label:Text(codeSent?'Ubah Kata Sandi':'Kirim Kode OTP'))),
          if(codeSent)...[
            const SizedBox(height:8),
            TextButton(
              onPressed:busy?null:requestOtp,
              child:const Text('Kirim ulang OTP (minimal 60 detik)')),
            TextButton(
              onPressed:busy?null:()=>setState((){
                codeSent=false;otp.clear();password.clear();confirm.clear();
              }),
              child:const Text('Ubah username atau email')),
          ],
          const SizedBox(height:16),
          const Text('Tidak menerima email? Periksa folder Spam. Jika email belum terdaftar, hubungi Admin Kelurahan Cikoko. Jangan berikan OTP kepada siapa pun.',
            textAlign:TextAlign.center,
            style:TextStyle(color:Colors.blueGrey,fontSize:12)),
        ]))),
    )),
  );
}
