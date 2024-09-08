import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

Future<String?> showCancelSurveyDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (_) => const _Survey(),
  );
}

class _Survey extends StatefulWidget {
  const _Survey();

  @override
  State<_Survey> createState() => _SurveyState();
}

class _SurveyState extends State<_Survey> {
  final PageController pageController = PageController();
  final Map<String, String> answers = {};

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: SizedBox(
        width: 674,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Survey title
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: FlowyText(
                            LocaleKeys.settings_cancelSurveyDialog_title.tr(),
                            fontSize: 22.0,
                            overflow: TextOverflow.ellipsis,
                            color: AFThemeExtension.of(context).strongText,
                          ),
                        ),
                        FlowyButton(
                          useIntrinsicWidth: true,
                          text: const FlowySvg(FlowySvgs.upgrade_close_s),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const VSpace(12),
                    // Survey explanation
                    FlowyText(
                      LocaleKeys.settings_cancelSurveyDialog_description.tr(),
                      maxLines: 3,
                    ),
                    const VSpace(8),
                    const Divider(),
                    const VSpace(8),
                    // Question "sheet"
                    SizedBox(
                      height: 400,
                      width: 650,
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: _questionsAndAnswers.length,
                        itemBuilder: (context, index) => _QAPage(
                          qa: _questionsAndAnswers[index],
                          isFirstQuestion: index == 0,
                          isFinalQuestion:
                              index == _questionsAndAnswers.length - 1,
                          selectedAnswer:
                              answers[_questionsAndAnswers[index].question],
                          onPrevious: () {
                            if (index > 0) {
                              pageController.animateToPage(
                                index - 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          onAnswerChanged: (answer) {
                            answers[_questionsAndAnswers[index].question] =
                                answer;
                          },
                          onAnswerSelected: (answer) {
                            answers[_questionsAndAnswers[index].question] =
                                answer;

                            if (index == _questionsAndAnswers.length - 1) {
                              Navigator.of(context).pop(jsonEncode(answers));
                            } else {
                              pageController.animateToPage(
                                index + 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QAPage extends StatefulWidget {
  const _QAPage({
    required this.qa,
    required this.onAnswerSelected,
    required this.onAnswerChanged,
    required this.onPrevious,
    this.selectedAnswer,
    this.isFirstQuestion = false,
    this.isFinalQuestion = false,
  });

  final _QA qa;
  final String? selectedAnswer;

  /// Called when "Next" is pressed
  ///
  final Function(String) onAnswerSelected;

  /// Called whenever an answer is selected or changed
  ///
  final Function(String) onAnswerChanged;
  final VoidCallback onPrevious;
  final bool isFirstQuestion;
  final bool isFinalQuestion;

  @override
  State<_QAPage> createState() => _QAPageState();
}

class _QAPageState extends State<_QAPage> {
  final otherController = TextEditingController();

  int _selectedIndex = -1;
  String? answer;

  @override
  void initState() {
    super.initState();
    if (widget.selectedAnswer != null) {
      answer = widget.selectedAnswer;
      _selectedIndex = widget.qa.answers.indexOf(widget.selectedAnswer!);
      if (_selectedIndex == -1) {
        // We assume the last question is "Other"
        _selectedIndex = widget.qa.answers.length - 1;
        otherController.text = widget.selectedAnswer!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText(
          widget.qa.question,
          fontSize: 16.0,
          color: AFThemeExtension.of(context).strongText,
        ),
        const VSpace(18),
        SeparatedColumn(
          separatorBuilder: () => const VSpace(6),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.qa.answers
              .mapIndexed(
                (index, option) => _AnswerOption(
                  prefix: _indexToLetter(index),
                  option: option,
                  isSelected: _selectedIndex == index,
                  onTap: () => setState(() {
                    _selectedIndex = index;
                    if (_selectedIndex == widget.qa.answers.length - 1 &&
                        widget.qa.lastIsOther) {
                      answer = otherController.text;
                    } else {
                      answer = option;
                    }
                    widget.onAnswerChanged(option);
                  }),
                ),
              )
              .toList(),
        ),
        if (widget.qa.lastIsOther &&
            _selectedIndex == widget.qa.answers.length - 1) ...[
          const VSpace(8),
          FlowyTextField(
            controller: otherController,
            hintText: LocaleKeys.settings_cancelSurveyDialog_otherHint.tr(),
            onChanged: (value) => setState(() {
              answer = value;
              widget.onAnswerChanged(value);
            }),
          ),
        ],
        const VSpace(20),
        Row(
          children: [
            if (!widget.isFirstQuestion) ...[
              DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0x1E14171B)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: FlowyButton(
                  useIntrinsicWidth: true,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 9.0,
                  ),
                  text: FlowyText.regular(LocaleKeys.button_previous.tr()),
                  onTap: widget.onPrevious,
                ),
              ),
              const HSpace(12.0),
            ],
            DecoratedBox(
              decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: FlowyButton(
                useIntrinsicWidth: true,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
                radius: BorderRadius.circular(8),
                text: FlowyText.regular(
                  widget.isFinalQuestion
                      ? LocaleKeys.button_submit.tr()
                      : LocaleKeys.button_next.tr(),
                  color: Colors.white,
                ),
                disable: !canProceed(),
                onTap: canProceed()
                    ? () => widget.onAnswerSelected(
                          answer ?? widget.qa.answers[_selectedIndex],
                        )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool canProceed() {
    if (_selectedIndex == widget.qa.answers.length - 1 &&
        widget.qa.lastIsOther) {
      return answer != null &&
          answer!.isNotEmpty &&
          answer != LocaleKeys.settings_cancelSurveyDialog_commonOther.tr();
    }

    return _selectedIndex != -1;
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.prefix,
    required this.option,
    required this.onTap,
    this.isSelected = false,
  });

  final String prefix;
  final String option;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: Corners.s8Border,
            border: Border.all(
              width: 2,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HSpace(2),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  borderRadius: Corners.s6Border,
                ),
                child: Center(
                  child: FlowyText(
                    prefix,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              ),
              const HSpace(8),
              FlowyText(
                option,
                fontWeight: FontWeight.w400,
                fontSize: 16.0,
                color: AFThemeExtension.of(context).strongText,
              ),
              const HSpace(6),
            ],
          ),
        ),
      ),
    );
  }
}

final _questionsAndAnswers = [
  _QA(
    question: LocaleKeys.settings_cancelSurveyDialog_questionOne_question.tr(),
    answers: [
      LocaleKeys.settings_cancelSurveyDialog_questionOne_answerOne.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionOne_answerTwo.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionOne_answerThree.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionOne_answerFour.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionOne_answerFive.tr(),
      LocaleKeys.settings_cancelSurveyDialog_commonOther.tr(),
    ],
    lastIsOther: true,
  ),
  _QA(
    question: LocaleKeys.settings_cancelSurveyDialog_questionTwo_question.tr(),
    answers: [
      LocaleKeys.settings_cancelSurveyDialog_questionTwo_answerOne.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionTwo_answerTwo.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionTwo_answerThree.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionTwo_answerFour.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionTwo_answerFive.tr(),
    ],
  ),
  _QA(
    question:
        LocaleKeys.settings_cancelSurveyDialog_questionThree_question.tr(),
    answers: [
      LocaleKeys.settings_cancelSurveyDialog_questionThree_answerOne.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionThree_answerTwo.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionThree_answerThree.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionThree_answerFour.tr(),
      LocaleKeys.settings_cancelSurveyDialog_commonOther.tr(),
    ],
    lastIsOther: true,
  ),
  _QA(
    question: LocaleKeys.settings_cancelSurveyDialog_questionFour_question.tr(),
    answers: [
      LocaleKeys.settings_cancelSurveyDialog_questionFour_answerOne.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionFour_answerTwo.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionFour_answerThree.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionFour_answerFour.tr(),
      LocaleKeys.settings_cancelSurveyDialog_questionFour_answerFive.tr(),
    ],
  ),
];

class _QA {
  const _QA({
    required this.question,
    required this.answers,
    this.lastIsOther = false,
  });

  final String question;
  final List<String> answers;
  final bool lastIsOther;
}

/// Returns the letter corresponding to the index.
///
/// Eg. 0 -> A, 1 -> B, 2 -> C, ..., and so forth.
///
String _indexToLetter(int index) {
  return String.fromCharCode(65 + index);
}
