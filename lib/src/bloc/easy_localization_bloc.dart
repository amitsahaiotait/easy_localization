import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../easy_localization.dart';
import '../translations.dart';

class Resource {
  final Locale locale;
  final AssetLoader assetLoader;
  final String path;
  final bool useOnlyLangCode;
  Translations _translations;
  
  Translations get translations => _translations;

  Resource({this.locale, this.assetLoader, this.path, this.useOnlyLangCode});

  String _getLocalePath() {
    final String _codeLang = locale.languageCode;
    final String _codeCoun = locale.countryCode;
    final String localePath = '$path/$_codeLang';
    return this.useOnlyLangCode  ? '$localePath.json' : '$localePath-$_codeCoun.json';
  }

  loadTranslations() async {
    var data = await assetLoader.load(_getLocalePath());
    _translations =Translations(data);
  }
}

class EasyLocalizationBloc {
  //
  // Constructor
  //
  EasyLocalizationBloc._internal(){
    _actionController.stream.listen(_onData, onError: _onError, cancelOnError: true);
  }
  factory EasyLocalizationBloc(){
    return EasyLocalizationBloc._internal();
  }
  //
  // Stream to handle the _easyLocalizationLocale
  //
  StreamController<Resource> _controller = StreamController<Resource>();
  StreamSink<Resource> get _inSink => _controller.sink;
  Stream<Resource> get outStream => _controller.stream.transform(validate);

  final validate = StreamTransformer<Resource, Resource>.fromHandlers(
    handleError: (error, stackTrace, sink) =>  sink.addError(error),
    handleData: (resource, sink) => sink.add(resource));

  //
  // Stream to handle the action on the _easyLocalizationLocale
  //
  StreamController<Resource> _actionController = StreamController<Resource>();
  Function(Resource) get onChange => _actionController.sink.add;
  Function get onError => _actionController.sink.addError;

  void dispose() {
    _actionController.close();
    _controller.close();
    // _localController.close();
  }

  void reassemble() async{
    //cloase and create new when hotreloaded or reloaded
    await _controller.close();
    _controller = StreamController<Resource>();
  }

  void _onData(Resource data) async{
    await data.loadTranslations();
    if(!_actionController.isClosed) _inSink.add(data);
  }

  void _onError(data){
    if(!_actionController.isClosed) _inSink.addError(data);
  }
}