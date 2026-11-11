import 'package:flutter/material.dart';

/// Pixel vocabulary taken from the approved Cikoko V4 app showcase:
/// white surfaces, navy text, thin blue borders, compact dimensions.
abstract final class CikokoPalette {
 static const navy=Color(0xFF0C1A48);
 static const dark=Color(0xFF081A3B);
 static const blue=Color(0xFF0967E7);
 static const surface=Colors.white;
 static const background=Color(0xFFF8FBFF);
 static const soft=Color(0xFFE9F3FF);
 static const muted=Color(0xFF61748C);
 static const border=Color(0xFFE0EAF5);
}
ThemeData cikokoUnifiedTheme(){
 const navy=CikokoPalette.navy;
 const blue=CikokoPalette.blue;
 const line=CikokoPalette.border;
 final round=RoundedRectangleBorder(
   borderRadius:BorderRadius.circular(12),
   side:const BorderSide(color:line));
 final input=OutlineInputBorder(
   borderRadius:BorderRadius.circular(9),
   borderSide:const BorderSide(color:line));
 return ThemeData(
  useMaterial3:true,
  brightness:Brightness.light,
  scaffoldBackgroundColor:CikokoPalette.background,
  canvasColor:CikokoPalette.background,
  colorScheme:ColorScheme.fromSeed(
   seedColor:blue,primary:blue,surface:Colors.white,
   onSurface:navy),
  appBarTheme:const AppBarTheme(
   backgroundColor:Colors.white,foregroundColor:navy,
   surfaceTintColor:Colors.transparent,elevation:0,
   toolbarHeight:58,titleSpacing:10,centerTitle:false,
   titleTextStyle:TextStyle(fontSize:15.5,color:navy,fontWeight:FontWeight.w800),
   iconTheme:IconThemeData(color:navy,size:22)),
  cardTheme:CardThemeData(color:Colors.white,surfaceTintColor:Colors.transparent,
    elevation:0,margin:const EdgeInsets.symmetric(vertical:4),
    shape:round,clipBehavior:Clip.antiAlias),
  inputDecorationTheme:InputDecorationTheme(
    isDense:true,filled:true,fillColor:Colors.white,
    labelStyle:const TextStyle(color:navy,fontSize:11.5),
    hintStyle:const TextStyle(color:CikokoPalette.muted,fontSize:11),
    contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:13),
    prefixIconColor:blue,
    border:input,enabledBorder:input,
    focusedBorder:input.copyWith(borderSide:const BorderSide(color:blue,width:1.4))),
  filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(
    backgroundColor:blue,foregroundColor:Colors.white,
    minimumSize:const Size(0,40),padding:const EdgeInsets.symmetric(horizontal:13),
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(9)),
    textStyle:const TextStyle(fontSize:12,fontWeight:FontWeight.w800))),
  outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(
    foregroundColor:navy,minimumSize:const Size(0,40),
    side:const BorderSide(color:line),
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(9)),
    textStyle:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))),
  textButtonTheme:TextButtonThemeData(style:TextButton.styleFrom(
    foregroundColor:blue,textStyle:const TextStyle(fontSize:11.5,fontWeight:FontWeight.w700))),
  chipTheme:ChipThemeData(
    backgroundColor:Colors.white,selectedColor:blue,
    checkmarkColor:Colors.white,
    side:const BorderSide(color:line),
    labelStyle:const TextStyle(fontSize:10.7,color:navy,fontWeight:FontWeight.w700),
    secondaryLabelStyle:const TextStyle(fontSize:10.7,color:Colors.white,fontWeight:FontWeight.w800),
    padding:const EdgeInsets.symmetric(horizontal:5,vertical:0),
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
  tabBarTheme:const TabBarThemeData(
    indicatorColor:blue,labelColor:blue,unselectedLabelColor:CikokoPalette.muted,
    labelStyle:TextStyle(fontWeight:FontWeight.w800,fontSize:12)),
  drawerTheme:const DrawerThemeData(backgroundColor:Colors.white,elevation:0),
  listTileTheme:const ListTileThemeData(
    textColor:navy,iconColor:blue,contentPadding:EdgeInsets.symmetric(horizontal:13),
    dense:true),
  dividerTheme:const DividerThemeData(color:line,space:1,thickness:1),
  dialogTheme:DialogThemeData(backgroundColor:Colors.white,
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),
  bottomSheetTheme:const BottomSheetThemeData(
    backgroundColor:Colors.white,showDragHandle:true,
    shape:RoundedRectangleBorder(
      borderRadius:BorderRadius.vertical(top:Radius.circular(17)))),
  snackBarTheme:const SnackBarThemeData(behavior:SnackBarBehavior.floating),
  textTheme:const TextTheme(
    headlineSmall:TextStyle(color:navy,fontSize:22,fontWeight:FontWeight.w900),
    titleLarge:TextStyle(color:navy,fontSize:18,fontWeight:FontWeight.w800),
    titleMedium:TextStyle(color:navy,fontSize:14,fontWeight:FontWeight.w800),
    bodyLarge:TextStyle(color:navy,fontSize:13),
    bodyMedium:TextStyle(color:navy,fontSize:12),
    bodySmall:TextStyle(color:CikokoPalette.muted,fontSize:10.8)),
 );
}
