/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/ui/widgets/ScalableScrollView.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

import 'package:sprintf/sprintf.dart';

class OnboardingLoginPhoneConfirmPanel extends StatefulWidget with OnboardingPanel {

  final Map<String, dynamic> onboardingContext;
  final String phoneNumber;
  final String verificationId;
  final ValueSetter<dynamic> onFinish;

  OnboardingLoginPhoneConfirmPanel({this.onboardingContext, this.phoneNumber, this.verificationId, this.onFinish});

  @override
  _OnboardingLoginPhoneConfirmPanelState createState() => _OnboardingLoginPhoneConfirmPanelState();

  @override
  bool get onboardingCanDisplay {
    return (onboardingContext != null) && onboardingContext['shouldVerifyPhone'] == true;
  }
}

class _OnboardingLoginPhoneConfirmPanelState extends State<OnboardingLoginPhoneConfirmPanel> {
  TextEditingController _codeController = TextEditingController();
  String _verificationErrorMsg;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    String phoneNumber = (widget.onboardingContext != null) ? widget.onboardingContext["phone"] : null;
    String maskedPhoneNumber = AppString.getMaskedPhoneNumber(phoneNumber);
    String description = sprintf(
        Localization().getStringEx(
            'panel.onboarding.confirm_phone.description.send', 'A one time code has been sent to %s. Enter your code below to continue.'),
        [maskedPhoneNumber]);

    if (Config().useMultiTenant) {
      AuthCredential authCredential = (widget.onboardingContext != null) ? widget.onboardingContext["authCredential"] : null;
      if (authCredential != null) {
        setState(() {
          _isLoading = true;
        });
        Auth()
            .firebaseSignInWithCredential(authCredential)
            .then((success) => {
          _onPhoneVerified(success)
        }).whenComplete((){
          if(mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.translucent,
        onTap: ()=>FocusScope.of(context).requestFocus(new FocusNode()),
        child:
            ScalableScrollView(
              scrollableChild:
              Stack(children: <Widget>[
              Padding(
              padding: EdgeInsets.only(left: 18, right: 18, top: 24, bottom: 24),
                child:
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 64, right: 64, bottom: 12),
                  child: Text(
                    Localization().getStringEx("panel.onboarding.confirm_phone.title",
                        "Confirm your code"),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 36, color: Styles().colors.fillColorPrimary),
                  ),
                ),
                Container(
                  height: 48,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 32),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        color: Styles().colors.fillColorPrimary,
                        fontFamily: Styles().fontFamilies.regular),
                  ),
                ),
                Container(
                  height: 26,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 6),
                  child: Text(
                    Localization().getStringEx(
                        "panel.onboarding.confirm_phone.code.label",
                        "One-time code"),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 16,
                        color: Styles().colors.fillColorPrimary,
                        fontFamily: Styles().fontFamilies.bold),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: Semantics(
                      excludeSemantics: true,
                      label: Localization().getStringEx("panel.onboarding.confirm_phone.code.label", "One-time code"),
                      hint: Localization().getStringEx("panel.onboarding.confirm_phone.code.hint", ""),
                      value: _codeController.text,
                      child: TextField(
                        controller: _codeController,
                        autofocus: false,
                        onSubmitted: (_) => _clearErrorMsg,
                        cursorColor: Styles().colors.textBackground,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: Styles().fontFamilies.regular,
                            color: Styles().colors.textBackground),
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.0,
                                style: BorderStyle.solid),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                      ),
                    )),
                Visibility(
                  visible: AppString.isStringNotEmpty(_verificationErrorMsg),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Text(
                      AppString.getDefaultEmptyString(
                          value: _verificationErrorMsg),
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: Styles().fontFamilies.medium),
                    ),
                  ),
                ),
                ])),
                Visibility(
                  visible: _isLoading,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                OnboardingBackButton(
                    padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20),
                    onTap:() {
                      Analytics.instance.logSelect(target: "Back");
                      Navigator.pop(context);
                    }),
              ]),
              bottomNotScrollableWidget:
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: ScalableRoundedButton(
                  label: Localization().getStringEx(
                      "panel.onboarding.confirm_phone.button.confirm.label",
                      "Confirm phone number"),
                  hint: Localization().getStringEx(
                      "panel.onboarding.confirm_phone.button.confirm.hint", ""),
                  borderColor: Styles().colors.fillColorSecondary,
                  backgroundColor: Styles().colors.background,
                  textColor: Styles().colors.fillColorPrimary,
                  onTap: () => _onTapConfirm()))
          ),),

      );
  }

  void _onTapConfirm() {

    if(_isLoading){
      return;
    }

    Analytics.instance.logSelect(target: "Confirm phone number");
    _clearErrorMsg();
    _validateCode();
    if (AppString.isStringNotEmpty(_verificationErrorMsg)) {
      return;
    }


    setState(() {
      _isLoading = true;
    });

    if (Config().useMultiTenant) {
      String verificationId = (widget.onboardingContext != null) ? widget.onboardingContext["verificationId"] : widget.verificationId;
      Auth()
          .firebaseValidatePhoneNumber(_codeController.text, verificationId)
          .then((success) => {
        _onPhoneVerified(success)
      }).whenComplete((){
        if(mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      String phoneNumber = (widget.onboardingContext != null) ? widget.onboardingContext["phone"] : widget.phoneNumber;

      Auth()
          .validatePhoneNumber(_codeController.text, phoneNumber)
          .then((success) => {
        _onPhoneVerified(success)
      }).whenComplete((){
        if(mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _onPhoneVerified(bool success) {
    if (!success) {
      setState(() {
        _verificationErrorMsg = Localization().getStringEx(
            "panel.onboarding.confirm_phone.validation.server_error.text",
            "Failed to verify code");
      });
    }
    else if (widget.onboardingContext != null) {
      widget.onboardingContext['shouldDisplayResidentInfo'] = true;
      Onboarding().next(context, widget);
    }
    else if (widget.onFinish != null) {
      widget.onFinish(widget);
    }
  }

  void _validateCode() {
    String phoneNumberValue = _codeController.text;
    if (AppString.isStringEmpty(phoneNumberValue)) {
      setState(() {
        _verificationErrorMsg = Localization().getStringEx(
            "panel.onboarding.confirm_phone.validation.phone_number.text",
            "Please, fill your code");
      });
      return;
    }
  }

  void _clearErrorMsg() {
    setState(() {
      _verificationErrorMsg = null;
    });
  }
}
