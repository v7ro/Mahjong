import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n.dart';
import 'main_menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> {
  static const kBurgundy = Color(0xFF6B1F2B);
  final _fs = FirebaseService();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _name  = TextEditingController();
  bool _reg=false, _loading=false;
  String? _err;

  @override void dispose() {
    _email.dispose(); _pass.dispose(); _name.dispose(); super.dispose();
  }

  void _go() => Navigator.pushReplacement(context,
    MaterialPageRoute(builder:(_)=>const MainMenuScreen()));

  Future<void> _forgotPassword() async {
    final e = _email.text.trim();
    if (e.isEmpty) {
      setState(() => _err = tr('Введите email для сброса пароля','Enter email to reset password'));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: e);
      setState(() => _err = tr('Письмо отправлено на $e','Reset email sent to $e'));
    } catch (_) {
      setState(() => _err = tr('Ошибка. Проверьте email','Error. Check email'));
    }
  }

  Future<void> _emailAuth() async {
    final e=_email.text.trim(), p=_pass.text.trim(), n=_name.text.trim();
    if (e.isEmpty||p.isEmpty) { setState(()=>_err=tr('Заполните все поля','Fill all fields')); return; }
    if (_reg&&n.isEmpty) { setState(()=>_err=tr('Введите имя','Enter name')); return; }
    if (_reg&&p.length<8) { setState(()=>_err=tr('Пароль минимум 8 символов','Password min 8 characters')); return; }
    if (_reg&&p.length<8) { setState(()=>_err=tr('Пароль должен содержать минимум 8 символов','Password must be at least 8 characters')); return; }
    setState(()=>(_loading=true,_err=null));
    final err = _reg
      ? await _fs.registerWithEmail(e,p,n)
      : await _fs.signInWithEmail(e,p);
    if (!mounted) return;
    if (err!=null) setState(()=>(_err=err,_loading=false));
    else _go();
  }

  Future<void> _google() async {
    setState(()=>_loading=true);
    final r = await _fs.signInWithGoogle();
    if (!mounted) return;
    if (r==null) setState(()=>(_err=tr('Вход отменён','Login cancelled'),_loading=false));
    else _go();
  }

  Future<void> _resetPassword() async {
    final e = _email.text.trim();
    if (e.isEmpty) {
      setState(() => _err = tr('Введите email для сброса пароля', 'Enter email to reset password'));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: e);
      setState(() => _err = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Письмо отправлено на $e', 'Email sent to $e'))));
    } catch (_) {
      setState(() => _err = tr('Ошибка. Проверьте email', 'Error. Check email'));
    }
  }

  Future<void> _apple() async {
    setState(()=>_loading=true);
    final r = await _fs.signInWithApple();
    if (!mounted) return;
    if (r==null) setState(()=>(_err=tr('Вход отменён','Login cancelled'),_loading=false));
    else _go();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(children: [
      Positioned.fill(child: Image.asset(
        'assets/images/backgrounds/loading.jpeg', fit:BoxFit.cover,
        errorBuilder:(_,__,___)=>Container(color:const Color(0xFF1a0a05)))),
      Positioned.fill(child: Container(color:const Color(0x80000000))),
      SafeArea(child: Center(child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(mainAxisSize:MainAxisSize.min, children: [
          const Text('麻將', style:TextStyle(fontSize:68, color:Colors.white,
            shadows:[Shadow(color:Colors.black54,blurRadius:12)])),
          const SizedBox(height:4),
          Text(_reg?tr('регистрация','register'):tr('вход','login'), style:TextStyle(
            fontSize:18, color:const Color(0xB3FFFFFF), fontFamily:'Aboreto', letterSpacing:3)),
          const SizedBox(height:28),
          Container(
            padding: EdgeInsets.all(22),
            decoration: BoxDecoration(color:Colors.white.withValues(alpha: 0.93),
              borderRadius:BorderRadius.circular(20)),
            child: Column(children: [
              if (_reg) ...[_field(_name,tr('Имя','Name'),Icons.person,action:TextInputAction.next), const SizedBox(height:10)],
              _field(_email,'Email',Icons.email, type:TextInputType.emailAddress, action:TextInputAction.next),
              const SizedBox(height:10),
              _field(_pass,'Пароль',Icons.lock,obscure:true),
              if (_err!=null) ...[
                const SizedBox(height:10),
                Text(_err!, style:const TextStyle(color:Colors.red,fontSize:13, fontFamily: 'Cormorant'),
                  textAlign:TextAlign.center)],
              const SizedBox(height:12),
              if (!_reg) Align(alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text(tr('Забыли пароль?','Forgot password?'),
                    style: const TextStyle(color: kBurgundy, fontSize: 13, fontFamily: 'Cormorant')))),
              const SizedBox(height:6),
              SizedBox(width:double.infinity, child: ElevatedButton(
                onPressed:_loading?null:_emailAuth,
                style:ElevatedButton.styleFrom(backgroundColor:kBurgundy,
                  padding:EdgeInsets.symmetric(vertical:14),
                  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
                child: _loading
                  ? const SizedBox(width:20,height:20,
                      child:CircularProgressIndicator(color:Colors.white,strokeWidth:2))
                  : Text(_reg?tr('зарегистрироваться','register'):tr('войти','sign in'),
                      style:const TextStyle(color:Colors.white,fontSize:15,fontFamily:'Aboreto')))),
              const SizedBox(height:8),
              if (!_reg) TextButton(
                onPressed: _resetPassword,
                child: Text(tr('забыли пароль?', 'forgot password?'),
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cormorant'))),
              TextButton(
                onPressed:()=>setState(()=>(_reg=!_reg,_err=null)),
                child:Text(_reg?tr('уже есть аккаунт? войти','already have account? sign in'):tr('нет аккаунта? регистрация','no account? register'),
                  style:const TextStyle(color:kBurgundy,fontSize:12, fontFamily: 'Cormorant'))),
              const Divider(height:20),
              _social(onTap:_loading?null:_google,
                icon:const Icon(Icons.g_mobiledata,size:22,color:Colors.black87),
                label:tr('войти через Google','sign in with Google'),
                bg:Colors.white,border:Colors.grey.shade300,tc:Colors.black87),
              if (Platform.isIOS||Platform.isMacOS) ...[
                const SizedBox(height:8),
                _social(onTap:_loading?null:_apple,
                  icon:const Icon(Icons.apple,size:22,color:Colors.white),
                  label:tr('войти через Apple','sign in with Apple'),
                  bg:Colors.black,border:Colors.black,tc:Colors.white)],
              const SizedBox(height:4),
              TextButton(
                onPressed:_loading?null:_go,
                child:Text(tr('продолжить без входа','continue without login'),
                  style:TextStyle(color:Colors.grey,fontSize:11, fontFamily: 'Cormorant'))),
            ])),
        ]),
      ))),
    ]));

  Widget _field(TextEditingController c, String hint, IconData icon,
      {bool obscure=false, TextInputType? type, TextInputAction? action}) =>
    TextField(controller:c, obscureText:obscure, keyboardType:type, textInputAction:action,
      enableInteractiveSelection:true, autocorrect:false,
      decoration:InputDecoration(hintText:hint, prefixIcon:Icon(icon,color:kBurgundy),
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(10),
          borderSide:BorderSide(color:Colors.grey.shade300)),
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(10),
          borderSide:BorderSide(color:Colors.grey.shade300)),
        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(10),
          borderSide:const BorderSide(color:kBurgundy,width:2)),
        filled:true, fillColor:Colors.grey.shade50));

  Widget _social({VoidCallback? onTap, required Widget icon, required String label,
      required Color bg, required Color border, required Color tc}) =>
    SizedBox(width:double.infinity, child:OutlinedButton(
      onPressed:onTap,
      style:OutlinedButton.styleFrom(backgroundColor:bg,side:BorderSide(color:border),
        padding:EdgeInsets.symmetric(vertical:11),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
      child:Row(mainAxisAlignment:MainAxisAlignment.center,
        children:[icon,const SizedBox(width:8),
          Text(label,style:TextStyle(color:tc,fontSize:13, fontFamily: 'Cormorant'))])));
}