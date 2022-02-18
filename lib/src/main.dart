import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'models/models.dart';

typedef Validator = String? Function(String tag);

class TextFieldTags extends StatefulWidget {
  ///[tagsStyler] must not be [null]
  final TagsStyler tagsStyler;

  ///[textFieldStyler] must not be [null]
  final TextFieldStyler textFieldStyler;

  ///[onTag] must not be [null] and should be implemented
  final void Function(String tag) onTag;

  final void Function(List<String> listTag) onList;

  ///[onDelete] must not be [null]
  final void Function(String tag) onDelete;

  ///[validator] allows you to validate the tag that has been entered
  final Validator? validator;

  ///[initialTags] are optional initial tags you can enter
  final List<String>? initialTags;

  ///Padding for the scrollable
  final EdgeInsets scrollableTagsPadding;

  ///Margin for the scrollable
  final EdgeInsets? scrollableTagsMargin;

  ///[tagsDistanceFromBorder] sets the distance of the tags from the border
  final double tagsDistanceFromBorderEnd;

  ///Enter optional String separators to split tags. Default is [","," ","\r"]
  final List<String>? textSeparators;

  final List<String>? tagsStringContents;

  const TextFieldTags({
    Key? key,
    this.tagsDistanceFromBorderEnd = 0.725,
    this.scrollableTagsPadding = const EdgeInsets.symmetric(horizontal: 4.0),
    this.scrollableTagsMargin,
    this.validator,
    this.initialTags,
    this.textSeparators = const [' ', ',', '\r', '\t'],
    required this.tagsStyler,
    required this.textFieldStyler,
    required this.onTag,
    required this.onList,
    required this.onDelete,
    this.tagsStringContents,
  }) : super(key: key);

  @override
  _TextFieldTagsState createState() => _TextFieldTagsState();
}

class _TextFieldTagsState extends State<TextFieldTags> {
  List<String>? tagsStringContents;
  TextEditingController? _textEditingController;
  ScrollController? _scrollController;
  late bool _showPrefixIcon;
  late double _deviceWidth;
  late bool _showValidator;
  late String _validatorMessage;

  @override
  void initState() {
    super.initState();
    _showValidator = false;
    _showPrefixIcon = false;
    tagsStringContents = [];

    _textEditingController = TextEditingController();
    _scrollController = ScrollController();
    if (widget.initialTags != null && widget.initialTags!.isNotEmpty) {
      _showPrefixIcon = true;
      tagsStringContents = widget.initialTags;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deviceWidth = MediaQuery.of(context).size.width;
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController!.dispose();
    _scrollController!.dispose();
    tagsStringContents = null;
    _textEditingController = null;
    _scrollController = null;
  }

  List<Widget> get _getTags {
    List<Widget> _tags = [];
    for (var i = 0; i < tagsStringContents!.length; i++) {
      final String stringContent = tagsStringContents![i];
      final String stringContentWithHash =
          widget.tagsStyler.showHashtag ? '#$stringContent' : stringContent;
      final Container tag = Container(
        padding: widget.tagsStyler.tagPadding,
        decoration: widget.tagsStyler.tagDecoration,
        margin: widget.tagsStyler.tagMargin,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: widget.tagsStyler.tagTextPadding,
              child: Text(
                stringContentWithHash,
                style: widget.tagsStyler.tagTextStyle,
              ),
            ),
            Padding(
              padding: widget.tagsStyler.tagCancelIconPadding,
              child: GestureDetector(
                onTap: () {
                  widget.onDelete(stringContent);
                  if(stringContent.startsWith('|---') && stringContent.endsWith('---|')){
                    setState(() {
                      tagsStringContents!.clear();
                      _showPrefixIcon = false;
                      _showValidator = false;
                    });
                  }
                  if (tagsStringContents!.length == 1 && _showPrefixIcon) {
                    setState(() {
                      tagsStringContents!.remove(stringContent);
                      _showPrefixIcon = false;
                      _showValidator = false;
                    });
                  } else {
                    setState(() {
                      tagsStringContents!.remove(stringContent);
                      _showValidator = false;
                    });
                  }
                  widget.onList.call(tagsStringContents!);
                },
                child: widget.tagsStyler.tagCancelIcon,
              ),
            ),
          ],
        ),
      );
      _tags.add(tag);
    }
    return _tags;
  }

  void _animateTransition() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (_scrollController!.hasClients) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textEditingController,
      autocorrect: false,
      cursorColor: widget.textFieldStyler.cursorColor,
      style: widget.textFieldStyler.textStyle,
      decoration: InputDecoration(
        icon: widget.textFieldStyler.icon,
        contentPadding: widget.textFieldStyler.contentPadding,
        isDense: widget.textFieldStyler.isDense,
        hintText: !_showPrefixIcon ? widget.textFieldStyler.hintText : null,
        hintStyle: !_showPrefixIcon ? widget.textFieldStyler.hintStyle : null,
        filled: widget.textFieldStyler.textFieldFilled,
        fillColor: widget.textFieldStyler.textFieldFilledColor,
        enabled: widget.textFieldStyler.textFieldEnabled,
        border: widget.textFieldStyler.textFieldBorder,
        focusedBorder: widget.textFieldStyler.textFieldFocusedBorder,
        disabledBorder: widget.textFieldStyler.textFieldDisabledBorder,
        enabledBorder: widget.textFieldStyler.textFieldEnabledBorder,
        prefixIcon: _showPrefixIcon
            ? ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: _deviceWidth * widget.tagsDistanceFromBorderEnd),
                child: Container(
                  margin: widget.scrollableTagsMargin,
                  padding: widget.scrollableTagsPadding,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _getTags,
                    ),
                  ),
                ),
              )
            : null,
      ),
      onSubmitted: (value) {
        if (_showValidator == false) {
          final String val = value.trim().toUpperCase();
          if (value.isNotEmpty) {
            _textEditingController!.clear();
            if (!tagsStringContents!.contains(val)) {
              if (widget.validator == null || widget.validator!(val) == null) {
                widget.onTag(val);
                if (!_showPrefixIcon) {
                  setState(() {
                    tagsStringContents!.add(val);
                    widget.onList(tagsStringContents!);
                    _showPrefixIcon = true;
                  });
                } else {
                  setState(() {
                    tagsStringContents!.add(val);
                    widget.onList(tagsStringContents!);
                  });
                }
                _animateTransition();
              } else {
                setState(() {
                  _showValidator = true;
                  _validatorMessage = widget.validator!(val)!;
                });
              }
            }
          }
        } else {
          setState(() {
            _showValidator = false;
          });
        }
      },
      onChanged: (value) {
        dev.log(value, name: '[Package]-smart_tags');
        if (_showValidator == false) {
          var containedSeparator = widget.textSeparators!
              .cast<String?>()
              .firstWhere((element) => value.contains(element!),
                  orElse: () => null);
          if (containedSeparator == null) return;
          final List<String> splitTagsList = value.split(containedSeparator);
          splitTagsList.removeWhere((element) => element == '');
          if (splitTagsList.isEmpty) {
            return;
          }

          if (splitTagsList.length > 1) {
            for (var item in splitTagsList) {
              _textEditingController!.clear();
              if (!tagsStringContents!.contains(item)) {
                if (widget.validator == null ||
                    widget.validator!(item) == null) {
                  widget.onTag(item.toString().toUpperCase());
                  if (!_showPrefixIcon) {
                    setState(() {
                      tagsStringContents!.add(item);
                      _showPrefixIcon = true;
                    });
                  } else {
                    setState(() {
                      tagsStringContents!.add(item);
                    });
                  }
                  widget.onList(tagsStringContents!);
                  _animateTransition();
                } else {
                  setState(() {
                    _showValidator = true;
                    _validatorMessage = widget.validator!(item)!;
                  });
                }
              }
            }
          } else {
            final String lastLastTag = splitTagsList[0].trim().toUpperCase();
            if (lastLastTag.isNotEmpty) {
              _textEditingController!.clear();
              if (!tagsStringContents!.contains(lastLastTag)) {
                if (widget.validator == null ||
                    widget.validator!(lastLastTag) == null) {
                  widget.onTag(lastLastTag);
                  if (!_showPrefixIcon) {
                    setState(() {
                      tagsStringContents!.add(lastLastTag);
                      _showPrefixIcon = true;
                    });
                  } else {
                    setState(() {
                      tagsStringContents!.add(lastLastTag);
                    });
                  }
                  widget.onList(tagsStringContents!);
                  _animateTransition();
                } else {
                  setState(() {
                    _showValidator = true;
                    _validatorMessage = widget.validator!(lastLastTag)!;
                  });
                }
              }
            }
          }
        } else {
          setState(() {
            _showValidator = false;
          });
        }
      },
    );
  }
}
