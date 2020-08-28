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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Onboarding.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/RoleGridButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/utils/Utils.dart';

class OnboardingSchoolsPanel extends StatefulWidget with OnboardingPanel {
  final Map<String, dynamic> onboardingContext;
  OnboardingSchoolsPanel({this.onboardingContext});

  @override
  _OnboardingSchoolsSelectionPanelState createState() =>
      _OnboardingSchoolsSelectionPanelState();
}

class _OnboardingSchoolsSelectionPanelState extends State<OnboardingSchoolsPanel> implements NotificationsListener {
  String _selectedSchool;
  bool _updating = false;

  bool get _allowNext => _selectedSchool != null;

  @override
  void initState() {
    _selectedSchool = Config().configSchoolClientID ?? null;
    _onExploreClicked();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      body: SafeArea(child: Column( children: <Widget>[
        Container(color: Styles().colors.white, child: Padding(padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Row(children: <Widget>[
            OnboardingBackButton(image: 'images/chevron-left.png', padding: const EdgeInsets.only(left: 10,),
                onTap:() {
                  Analytics.instance.logSelect(target: "Back");
                  Navigator.pop(context);
                }),
            Expanded(child: Column(children: <Widget>[
              Semantics(
                label: Localization().getStringEx('panel.onboarding.schools.label.title', 'Select your school').toLowerCase(),
                hint: Localization().getStringEx('panel.onboarding.schools.label.title.hint', 'Header 1').toLowerCase(),
                excludeSemantics: true,
                child: Text(Localization().getStringEx('panel.onboarding.schools.label.title', 'Select your school'),
                  style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 24, color: Styles().colors.fillColorPrimary),
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 8),
                child: Text(Localization().getStringEx('panel.onboarding.schools.label.description', 'Select one'),
                  style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground),
                ),
              )
            ],),),
            Padding(padding: EdgeInsets.only(left: 42),),
          ],),
        ),),

        Expanded(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.only(left: 16, right: 8, ), child:
        _buildSchoolButtons(),),),),

        Container(color: Styles().colors.white, child: Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 20),
          child: Stack(children:<Widget>[
            RoundedButton(
                label: _allowNext ? Localization().getStringEx('panel.onboarding.schools.button.continue.enabled.title', 'Confirm') : Localization().getStringEx('panel.onboarding.schools.button.continue.disabled.title', 'Select one'),
                hint: Localization().getStringEx('panel.onboarding.schools.button.continue.hint', ''),
                enabled: _allowNext,
                height: 48,
                backgroundColor: (_allowNext ? Styles().colors.white : Styles().colors.background),
                borderColor: (_allowNext
                    ? Styles().colors.fillColorSecondary
                    : Styles().colors.fillColorPrimaryTransparent03),
                textColor: (_allowNext
                    ? Styles().colors.fillColorPrimary
                    : Styles().colors.fillColorPrimaryTransparent03),
                onTap: () => _onExploreClicked()),
            Visibility(
              visible: _updating,
              child: Container(
                height: 48,
                child: Align(
                  alignment:Alignment.center,
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary),),),),),),
          ]),
        ),)

      ],),),
    );
  }

  Widget _buildSchoolButtons() {
    final double gridSpacing = 5;
    List<Widget> schoolButtonRows = [];
    Config().schoolConfigs.insert(0, {"clientID" : "uiuc", "name" : "UIUC", "icon_url" : "https://upload.wikimedia.org/wikipedia/commons/7/7c/Illinois_Block_I.png"});
    if (AppCollection.isCollectionNotEmpty(Config().schoolConfigs)) {
      List<Widget> row = [];
      for (dynamic config in Config().schoolConfigs) {
        if (config is Map) {
          if (row.length == 3) {
            schoolButtonRows.add(Row(children: row));
            row = [];
          }

          if (row.length == 1) {
            row.add(Container(height: gridSpacing));
          }

          row.add(
            Flexible(flex: 1, child: RoleGridButton(
              title: config['name'],
              hint: config['name'],
              iconPath: config['icon_url'],
              selectedIconPath: config['icon_url'],
              selectedBackgroundColor: Styles().colors.fillColorSecondary,
              selected: (_selectedSchool == config['clientID']),
              data: config['clientID'],
              sortOrder: 1,
              onTap: _onSchoolGridButton,
            ),)
          );
        }
      }

      if (row.length != 0) {
        schoolButtonRows.add(Row(children: row));
      }
    }

    return Column(children: schoolButtonRows);

//    return Column(children: <Widget>[
//      Row(children: <Widget>[
//        Flexible(flex: 1, child: RoleGridButton(
//          title: Localization().getStringEx('panel.onboarding.schools.button.uiuc.title', 'UIUC'),
//          hint: Localization().getStringEx('panel.onboarding.schools.button.uiuc.hint', ''),
//          iconPath: 'images/icon-persona-student-normal.png',
//          selectedIconPath: 'images/icon-persona-student-selected.png',
//          selectedBackgroundColor: Styles().colors.fillColorSecondary,
//          selected: (_selectedSchool == ConfigSchool.uiuc),
//          data: ConfigSchool.uiuc,
//          sortOrder: 1,
//          onTap: _onSchoolGridButton,
//        ),),
//        Container(height: gridSpacing,),
//        Flexible(flex: 1, child: RoleGridButton(
//          title: Localization().getStringEx('panel.onboarding.schools.button.uic.title', 'UIC'),
//          hint: Localization().getStringEx('panel.onboarding.schools.button.uic.hint', ''),
//          iconPath: 'images/icon-persona-employee-normal.png',
//          selectedIconPath: 'images/icon-persona-employee-selected.png',
//          selectedBackgroundColor: Styles().colors.accentColor3,
//          selected: (_selectedSchool == ConfigSchool.uic),
//          data: ConfigSchool.uic,
//          sortOrder: 4,
//          onTap: _onSchoolGridButton,
//        ),)
//      ],),
//      Row(children: <Widget>[
//        Expanded(child: RoleGridButton(
//          title: Localization().getStringEx('panel.onboarding.schools.button.uis.title', 'UIS'),
//          hint: Localization().getStringEx('panel.onboarding.schools.button.uis.hint', ''),
//          iconPath: 'images/icon-persona-resident-normal.png',
//          selectedIconPath: 'images/icon-persona-resident-selected.png',
//          selectedBackgroundColor: Styles().colors.fillColorPrimary,
//          selectedTextColor: Colors.white,
//          selected: (_selectedSchool == ConfigSchool.uis),
//          data: ConfigSchool.uis,
//          sortOrder: 7,
//          onTap: _onSchoolGridButton,
//        ),),
////            Container(height: gridSpacing,),
////            Flexible(flex: 1, child: RoleGridButton(
////              title: Localization().getStringEx('panel.onboarding.schools.button.none.title', 'None'),
////              hint: Localization().getStringEx('panel.onboarding.schools.button.uic.hint', ''),
////              iconPath: 'images/icon-persona-resident-normal.png',
////              selectedIconPath: 'images/icon-persona-resident-selected.png',
////              selectedBackgroundColor: Styles().colors.accentColor2,
////              selected: (_selectedSchool == ConfigSchool.none),
////              data: ConfigSchool.none,
////              sortOrder: 10,
////              onTap: _onSchoolGridButton,
////            ),)
//      ],),
//    ],);
  }

  void _onSchoolGridButton(RoleGridButton button) {
    if (button != null) {

      String configSchool = button.data as String;

      Analytics.instance.logSelect(target: "School: " + configSchool);

      _selectedSchool = configSchool;

      setState(() {});
    }
  }

  void _onExploreClicked() {
    Analytics.instance.logSelect(target:"Confirm");
    if (_selectedSchool != null && !_updating) {
      Config().configSchoolClientID = _selectedSchool;
      setState(() { _updating = true; });
      FlexUI().update().then((_){
        if (mounted) {
          setState(() { _updating = false; });
          Onboarding().next(context, widget);
        }
      });
    }
  }

  @override
  void onNotification(String name, param) {
    if (name == Config.notifyConfigChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}