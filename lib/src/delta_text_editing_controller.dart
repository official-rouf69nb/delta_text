
import 'package:flutter/material.dart';
import 'package:quill_delta/quill_delta.dart';
import 'dart:math' as math;

class DeltaTextEditingController extends TextEditingController {
  var doc = Delta();
  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    List<TextSpan> children = [];
    doc.toList().forEach((element) {
      if(element.isNotEmpty){
        children.add(TextSpan(text: element.data, style: style.copyWith(
          color: element.attributes != null && element.attributes["color"]=="red"?Colors.redAccent: Colors.black,
          decoration: element.attributes != null && element.attributes["strike"]==true?TextDecoration.lineThrough:TextDecoration.none,
        )));
      }
    });
    return TextSpan(style: style, children: children);
  }
  
  String _oldText = "";
  void changeText(String text){
    int _oldLength = _oldText.length -1;
    int _newLength = text.length -1;
    int startPosition = selection.baseOffset;
    try {
      if(_oldLength < _newLength){
        //Just added new thing
        _addedText(text.substring(startPosition - 1,startPosition +(_newLength - _oldLength)-1));
      }
      else if(_oldLength > _newLength){
        if(startPosition == 0){
          _removedText(_oldText.substring(startPosition,startPosition + (_oldLength - _newLength)));
        }
        else if(_oldLength != _newLength && startPosition != _newLength && text[startPosition-1] == _oldText[startPosition-1]){
          //Just removed thing
          _removedText(_oldText.substring(startPosition,startPosition + (_oldLength - _newLength)));
        }else{
          //Removed and added thing
          _replacedText(_oldText.substring(startPosition-1,startPosition + (_oldLength - _newLength)),text.substring(startPosition - 1,startPosition));
        }
      }
      else if(_oldLength == _newLength){
        //Just replaced something
        _replacedText(_oldText.substring(startPosition-1, startPosition ),text.substring(startPosition-1, startPosition));
      }
    } catch (e) {
      reset();
    }
    _oldText = text;
  }

  _addedText(String text){
    var change = new Delta()
      ..retain(math.min(selection.baseOffset, selection.extentOffset) -1)
      ..insert(text);
    doc = doc.compose(change);
    notifyListeners();
  }
  _removedText(String text){
    var change = new Delta()
      ..retain(math.min(selection.baseOffset, selection.extentOffset))
      ..delete(text.length);
    doc = doc.compose(change);
    notifyListeners();
  }
  _replacedText(String oldText, String newText) {
    var change = new Delta()
      ..retain(math.min(selection.baseOffset, selection.extentOffset)-1)
      ..delete(oldText.length)
      ..insert(newText);
    doc = doc.compose(change);
    notifyListeners();
  }

  void setColorRed(){
    if(text.length >0 && !selection.isCollapsed && selection.baseOffset != selection.extentOffset){
      var change = new Delta()
        ..retain(math.min(selection.baseOffset, selection.extentOffset))
        ..retain(math.max(selection.baseOffset, selection.extentOffset) - math.min(selection.baseOffset, selection.extentOffset),{"color":"red"});
      doc = doc.compose(change);
      notifyListeners();
    }
  }
  void clearColorRed(){
    if(text.length >0 && !selection.isCollapsed && selection.baseOffset != selection.extentOffset){
      var change = new Delta()
        ..retain(math.min(selection.baseOffset, selection.extentOffset))
        ..retain(math.max(selection.baseOffset, selection.extentOffset) - math.min(selection.baseOffset, selection.extentOffset),{"color":null});
      doc = doc.compose(change);
      notifyListeners();
    }
  }
  void setStrikeThrough(){
    if(text.length >0 && !selection.isCollapsed && selection.baseOffset != selection.extentOffset){
      var change = new Delta()
        ..retain(math.min(selection.baseOffset, selection.extentOffset))
        ..retain(math.max(selection.baseOffset, selection.extentOffset) - math.min(selection.baseOffset, selection.extentOffset),{"strike":true});
      doc = doc.compose(change);
      notifyListeners();
    }
  }
  void clearStrikeThrough(){
    if(text.length >0 && !selection.isCollapsed && selection.baseOffset != selection.extentOffset){
      var change = new Delta()
        ..retain(math.min(selection.baseOffset, selection.extentOffset))
        ..retain(math.max(selection.baseOffset, selection.extentOffset) - math.min(selection.baseOffset, selection.extentOffset),{"strike":null});
      doc = doc.compose(change);
      notifyListeners();
    }
  }
  void reset(){
    if(text != null){
      doc = Delta()..insert(text);
      _oldText = text;
      notifyListeners();
    }
  }

  String getHtml(){
    String result="";
    try {
      doc.toList().forEach((element) {
        var data = element.value.toString().replaceAll('\n', "<br>");
        if(element.attributes == null) {
          result += data;
        }else{
          if(element.attributes["color"]!= null && element.attributes["strike"]!= null){
            result += """<s style="color: red;">$data</s>""";
          } else if(element.attributes["color"]!= null && element.attributes["strike"]== null){
            result += """<span style="color: red;">$data</span>""";
          } else if(element.attributes["color"]== null && element.attributes["strike"]!= null){
            result += """<s>$data</s>""";
          }
        }
      });
    }catch (e) {
    }
    return result;
  }

  void setHtml(String value){
    if(value != null){
      try {
        final String lineBreak = '<br>';
        final String onlyRead = '<span style="color: red;">';
        final String readStrike = '<s style="color: red;">';
        final String onlyStrike = '<s>';

        var delta = Delta();
        var segmentedHtml = value.replaceAll('<span class="ql-cursor"></span>', '').replaceFirst('<p>', '').split('<p>').map((e) => e.replaceAll('<p>', '').replaceAll('</p>', '')).toList();
        segmentedHtml.asMap().forEach((index,element) {
          if(index != 0){
            delta.insert('\n');
          }
          element.split('</span>').forEach((a) {
            a.split('</s>').forEach((z) {
              z.split('<br>').forEach((x) {
                if(x.isNotEmpty) {
                  if(x.contains(lineBreak)){
                    var prefix = x.substring(0,x.lastIndexOf(lineBreak));
                    var postfix = x.substring(x.lastIndexOf(lineBreak)+lineBreak.length);
                    if(prefix.isNotEmpty){
                      delta.insert(prefix);
                    }
                    delta.insert('\n');
                    if(postfix.isNotEmpty) {
                      delta.insert(postfix);
                    }
                  }else if(x.contains(onlyRead)){
                    var prefix = x.substring(0,x.lastIndexOf(onlyRead));
                    var postfix = x.substring(x.lastIndexOf(onlyRead)+onlyRead.length);
                    if(prefix.isNotEmpty){
                      delta.insert(prefix);
                    }
                    delta.insert(postfix,{"color":"red"});
                  }else if(x.contains(readStrike)){
                    var prefix = x.substring(0,x.lastIndexOf(readStrike));
                    var postfix = x.substring(x.lastIndexOf(readStrike)+readStrike.length);
                    if(prefix.isNotEmpty){
                      delta.insert(prefix);
                    }
                    delta.insert(postfix,{"color":"red","strike":true});
                  }else if(x.contains(onlyStrike)){
                    var prefix = x.substring(0,x.lastIndexOf(onlyStrike));
                    var postfix = x.substring(x.lastIndexOf(onlyStrike)+onlyStrike.length);
                    if(prefix.isNotEmpty){
                      delta.insert(prefix);
                    }
                    delta.insert(postfix,{"strike":true});
                  }else{
                    delta.insert(x);
                  }
                }
              });
            });
          });
        });

        this.text = delta.toList().map((e) => e.value).join();
        _oldText= this.text;
        doc = delta;
        notifyListeners();
      }catch (e) {
        reset();
      }
    }
  }
}