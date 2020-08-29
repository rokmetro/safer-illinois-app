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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/health/debug/Covid19DebugActionPanel.dart';
import 'package:illinois/ui/health/debug/Covid19DebugCreateEventPanel.dart';
import 'package:illinois/ui/health/debug/Covid19DebugExposureLogsPanel.dart';
import 'package:illinois/ui/health/debug/Covid19DebugExposurePanel.dart';
import 'package:illinois/ui/health/debug/Covid19DebugKeysPanel.dart';
import 'package:illinois/ui/health/debug/Covid19DebugSymptomsPanel.dart';
import 'package:illinois/ui/health/debug/Covid19DebugPendingEventsPanel.dart';
import 'package:illinois/ui/health/debug/Covid19DebugTraceContactPanel.dart';
import 'package:illinois/ui/settings/debug/SettingsDebugMessagingPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';

import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class SettingsDebugPanel extends StatefulWidget {
  @override
  _SettingsDebugPanelState createState() => _SettingsDebugPanelState();
}

class _SettingsDebugPanelState extends State<SettingsDebugPanel> {

  DateTime _offsetDate;
  ConfigEnvironment _selectedEnv;

  final TextEditingController _mapThresholdDistanceController = TextEditingController();

  @override
  void initState() {
    
    _offsetDate = Storage().offsetDate;
    
    _mapThresholdDistanceController.text = '${Storage().debugMapThresholdDistance}';

    _selectedEnv = Config().configEnvironment;

    super.initState();
  }

  @override
  void dispose() {
    
    // Map Threshold Distance
    int mapThresholdDistance = (_mapThresholdDistanceController.text != null) ? int.tryParse(_mapThresholdDistanceController.text) : null;
    if (mapThresholdDistance != null) {
      Storage().debugMapThresholdDistance = mapThresholdDistance;
    }
    _mapThresholdDistanceController.dispose();


    super.dispose();
  }

  String get _userDebugData{
    String userDataText = prettyPrintJson((User()?.data?.toJson()));
    String authInfoText = prettyPrintJson(Auth()?.authInfo?.toJson());
    String userData =  "UserData: " + (userDataText ?? "unknown") + "\n\n" +
        "AuthInfo: " + (authInfoText ?? "unknown");
    return userData;
  }

  @override
  Widget build(BuildContext context) {
    String userUuid = User().uuid;
    String pid = Storage().userPid;
    String firebaseProjectId = FirebaseMessaging().projectID;
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx("panel.debug.header.title", "Debug"),
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: SafeArea(
                child: Container(
                  color: Styles().colors.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Text(AppString.isStringNotEmpty(userUuid) ? 'Uuid: $userUuid' : "unknown uuid"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Text(AppString.isStringNotEmpty(pid) ? 'PID: $pid' : "unknown pid"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Text('Firebase: $firebaseProjectId'),
                      ),
                      
                      Container(height: 1, color: Styles().colors.surfaceAccent),
                      ToggleRibbonButton(label: 'Display all times in Central Time', toggled: !Storage().debugUseDeviceLocalTimeZone, onTap: _onUseDeviceLocalTimeZoneToggled),
                      ToggleRibbonButton(label: 'Show map location source', toggled: Storage().debugMapLocationProvider, onTap: _onMapLocationProvider),
                      ToggleRibbonButton(label: 'Show map levels', toggled: !Storage().debugMapHideLevels, onTap: _onMapShowLevels),
                      Container(height: 1, color: Styles().colors.surfaceAccent),
                      Container(color: Colors.white, child: Padding(padding: EdgeInsets.only(top: 5), child: Container(height: 1, color: Styles().colors.surfaceAccent))),
                      Container(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: TextFormField(
                                controller: _mapThresholdDistanceController,
                                keyboardType: TextInputType.number,
                                validator: _validateThresoldDistance,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(), hintText: "Enter map threshold distance in meters", labelText: 'Threshold Distance (meters)')),
                          )),
                      Container(color: Colors.white, child: Padding(padding: EdgeInsets.only(top: 5), child: Container(height: 1, color: Styles().colors.surfaceAccent))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Padding(
                        padding: EdgeInsets.only(left: 16), child: Text('Config Environment: '),), ListView.separated(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        separatorBuilder: (context, index) => Divider(color: Colors.transparent),
                        itemCount: ConfigEnvironment.values.length,
                        itemBuilder: (context, index) {
                          ConfigEnvironment environment = ConfigEnvironment.values[index];
                          RadioListTile widget = RadioListTile(
                              title: Text(configEnvToString(environment)), value: environment, groupValue: _selectedEnv, onChanged: _onConfigChanged);
                          return widget;
                        },
                      )
                      ],),),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              child: RoundedButton(
                                label: "Clear Offset",
                                backgroundColor: Styles().colors.background,
                                fontSize: 16.0,
                                textColor: Styles().colors.fillColorPrimary,
                                borderColor: Styles().colors.fillColorPrimary,
                                onTap: () {
                                  _clearDateOffset();
                                },
                              )),
                          Expanded(
                              child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: Text(_offsetDate != null ? AppDateTime().formatDateTime(_offsetDate, format: AppDateTime.gameResponseDateTimeFormat2) : "None",
                                textAlign: TextAlign.end),
                          ))
                        ],
                      ),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                            label: "Sports Offset",
                            backgroundColor: Styles().colors.background,
                            fontSize: 16.0,
                            textColor: Styles().colors.fillColorPrimary,
                            borderColor: Styles().colors.fillColorPrimary,
                            onTap: () {
                              _changeDate();
                            },
                          )),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "Messaging",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onMessagingClicked())),
                      Visibility(
                        visible: true,
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            child: RoundedButton(
                                label: "User Profile Info",
                                backgroundColor: Styles().colors.background,
                                fontSize: 16.0,
                                textColor: Styles().colors.fillColorPrimary,
                                borderColor: Styles().colors.fillColorPrimary,
                                onTap: _onUserProfileInfoClicked(context))),
                      ),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "COVID-19: Keys",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapCovid19Keys)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "COVID-19 Create Event",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapCreateCovid19Event)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "COVID-19 Pending Events",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapCovid19PendingEvents)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "COVID-19 Trace Contact",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapTraceCovid19Contact)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "COVID-19 Report Symptoms",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapReportCovid19Symptoms)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "COVID-19 Create Action",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapCreateCovid19Action)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "COVID-19 Exposures",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapCovid19Exposures)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: RoundedButton(
                              label: "COVID-19 Exposure Logs",
                              backgroundColor: Styles().colors.background,
                              fontSize: 16.0,
                              textColor: Styles().colors.fillColorPrimary,
                              borderColor: Styles().colors.fillColorPrimary,
                              onTap: _onTapCovid19ExposureLogs)),
                      Padding(padding: EdgeInsets.only(top: 5), child: Container()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  // Helpers

  String _validateThresoldDistance(String value) {
    return (int.tryParse(value) == null) ? 'Please enter a number.' : null;
  }

  _clearDateOffset() {
    setState(() {
      Storage().offsetDate = _offsetDate = null;
    });
  }

  _changeDate() async {
    DateTime offset = _offsetDate ?? DateTime.now();

    DateTime firstDate = DateTime.fromMillisecondsSinceEpoch(offset.millisecondsSinceEpoch).add(Duration(days: -365));
    DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(offset.millisecondsSinceEpoch).add(Duration(days: 365));

    DateTime date = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: offset,
      builder: (BuildContext context, Widget child) {
        return Theme(
          data: ThemeData.light(),
          child: child,
        );
      },
    );

    if (date == null) return;

    TimeOfDay time = await showTimePicker(context: context, initialTime: new TimeOfDay(hour: date.hour, minute: date.minute));
    if (time == null) return;

    int endHour = time != null ? time.hour : date.hour;
    int endMinute = time != null ? time.minute : date.minute;
    offset = new DateTime(date.year, date.month, date.day, endHour, endMinute);

    setState(() {
      Storage().offsetDate = _offsetDate = offset;
    });
  }

  void _onMapLocationProvider() {
    setState(() {
      Storage().debugMapLocationProvider = !Storage().debugMapLocationProvider;
    });
  }

  void _onMapShowLevels() {
    setState(() {
      Storage().debugMapHideLevels = !Storage().debugMapHideLevels;
    });
  }

  void _onUseDeviceLocalTimeZoneToggled() {
    setState(() {
      Storage().debugUseDeviceLocalTimeZone = !Storage().debugUseDeviceLocalTimeZone;
    });
  }

  Function _onMessagingClicked() {
    return () {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsDebugMessagingPanel()));
    };
  }

  Function _onUserProfileInfoClicked(BuildContext context) {
    return () {
      showDialog(
          context: context,
          builder: (_) => Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
            child:
            Dialog(
              //backgroundColor: Color(0x00ffffff),
                child:Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        color: Styles().colors.fillColorPrimary,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(width: 20,),
                            Expanded(
                              child: RoundedButton(
                                label: "Copy to clipboard",
                                borderColor: Styles().colors.fillColorSecondary,
                                onTap: _onTapCopyToClipboard,
                              ),
                            ),
                            Container(width: 20,),
                            GestureDetector(
                              onTap:  ()=>Navigator.of(context).pop(),
                              child: Padding(
                                padding: EdgeInsets.only(right: 10, top: 10),
                                child: Text('\u00D7',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: Styles().fontFamilies.medium,
                                      fontSize: 50
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container( child:
                            SingleChildScrollView(
                          child: Container(color: Styles().colors.background, child:Text(_userDebugData))
                        )
                        )
                      )
                    ]
                  )
                )
            )
          )
      );
    };
  }

  void _onTapCopyToClipboard(){
    Clipboard.setData(ClipboardData(text:_userDebugData)).then((_){
      AppToast.show("User data has been copied to the clipboard!");
    });
  }

  void _onTapCovid19Keys() {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Covid19DebugKeysPanel()));
  }

  void _onTapCreateCovid19Event() {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Covid19DebugCreateEventPanel()));
  }

  void _onTapCovid19PendingEvents() {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Covid19DebugPendingEventsPanel()));
  }

  void _onTapTraceCovid19Contact() {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Covid19DebugTraceContactPanel()));
  }

  void _onTapReportCovid19Symptoms() {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Covid19DebugSymptomsPanel()));
  }

  void _onTapCreateCovid19Action() {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Covid19DebugActionPanel()));
  }

  void _onTapCovid19Exposures() {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Covid19DebugExposurePanel()));
  }

  void _onTapCovid19ExposureLogs() {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Covid19DebugExposureLogsPanel()));
  }

  String prettyPrintJson(var input){
    if(input == null)
      return input;

    JsonEncoder encoder = JsonEncoder.withIndent('  ');
    var prettyString = encoder.convert(input);

    return prettyString;
  }

  void _onConfigChanged(dynamic env) {
    if (env is ConfigEnvironment) {
      setState(() {
        Config().configEnvironment = env;
        _selectedEnv = Config().configEnvironment;
      });
    }
  }

  // SettingsListenerMixin

  void onDateOffsetChanged() {
    setState(() {
      _offsetDate = Storage().offsetDate;
    });
  }
}
