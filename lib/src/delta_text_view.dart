import 'package:flutter/material.dart';
import 'package:quill_delta/quill_delta.dart';

class DeltaText extends StatelessWidget {
  final String htmlText;
  final TextStyle textStyle;
  final TextAlign textAlign;

  final Delta _delta = Delta();
  DeltaText({Key key, this.htmlText, this.textStyle, this.textAlign,}) {
    try {
      final String lineBreak = '<br>';
      final String onlyRead = '<span style="color: red;">';
      final String readStrike = '<s style="color: red;">';
      final String onlyStrike = '<s>';

      var segmentedHtml = htmlText.replaceAll('<span class="ql-cursor"></span>', '').replaceFirst('<p>', '').split('<p>').map((e) => e.replaceAll('<p>', '').replaceAll('</p>', '')).toList();
      segmentedHtml.asMap().forEach((index,element) {
        if(index != 0){
          _delta.insert('\n');
        }
        element.split('</span>').forEach((a) {
          a.split('</s>').forEach((z) {
            z.split('<br>').forEach((x) {
              if(x.isNotEmpty) {
                if(x.contains(lineBreak)){
                  var prefix = x.substring(0,x.lastIndexOf(lineBreak));
                  var postfix = x.substring(x.lastIndexOf(lineBreak)+lineBreak.length);
                  if(prefix.isNotEmpty){
                    _delta.insert(prefix);
                  }
                  _delta.insert('\n');
                  if(postfix.isNotEmpty) {
                    _delta.insert(postfix);
                  }
                }else if(x.contains(onlyRead)){
                  var prefix = x.substring(0,x.lastIndexOf(onlyRead));
                  var postfix = x.substring(x.lastIndexOf(onlyRead)+onlyRead.length);
                  if(prefix.isNotEmpty){
                    _delta.insert(prefix);
                  }
                  _delta.insert(postfix,{"color":"red"});
                }else if(x.contains(readStrike)){
                  var prefix = x.substring(0,x.lastIndexOf(readStrike));
                  var postfix = x.substring(x.lastIndexOf(readStrike)+readStrike.length);
                  if(prefix.isNotEmpty){
                    _delta.insert(prefix);
                  }
                  _delta.insert(postfix,{"color":"red","strike":true});
                }else if(x.contains(onlyStrike)){
                  var prefix = x.substring(0,x.lastIndexOf(onlyStrike));
                  var postfix = x.substring(x.lastIndexOf(onlyStrike)+onlyStrike.length);
                  if(prefix.isNotEmpty){
                    _delta.insert(prefix);
                  }
                  _delta.insert(postfix,{"strike":true});
                }else{
                  _delta.insert(x);
                }
              }
            });
          });
        });
      });
    }catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TextSpan> children = [];
    _delta.toList().forEach((element) {
      if(element.isNotEmpty){
        children.add(TextSpan(text: element.data, style: (textStyle??DefaultTextStyle.of(context).style).copyWith(
          color: element.attributes != null && element.attributes["color"]=="red"?Colors.redAccent: Colors.black,
          decoration: element.attributes != null && element.attributes["strike"]==true?TextDecoration.lineThrough:TextDecoration.none,
        )));
      }
    });
    return RichText(
      text: TextSpan(style: textStyle, children: children),
    );
  }
}
