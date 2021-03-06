import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/theme/theme.dart';
import 'package:gc_wizard/widgets/common/base/gcw_divider.dart';
import 'package:gc_wizard/widgets/common/base/gcw_text.dart';
import 'package:gc_wizard/widgets/main_menu/gcw_mainmenuentry_stub.dart';
import 'package:gc_wizard/widgets/utils/common_widget_utils.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

final ABOUT_MAINTAINER = 'Mark \'S-Man42\' Lorenz';
final ABOUT_EMAIL = 'geocache.wizard' + String.fromCharCode(64) + 'gmail.com';
final ABOUT_EMAIL_URL = 'mailto:geocache.wizard' + String.fromCharCode(64) + 'gmail.com';
final ABOUT_WEBSITE = 'gcwizard.net';
final ABOUT_WEBSITE_URL = 'https://gcwizard.net/';
final ABOUT_BLOG = 'blog.gcwizard.net';
final ABOUT_BLOG_URL = 'https://blog.gcwizard.net/';
final ABOUT_TWITTER = '@gc_wizard';
final ABOUT_TWITTER_URL = 'https://twitter.com/gc_wizard';
final ABOUT_FACEBOOK = '@geocache.wizard';
final ABOUT_FACEBOOK_URL = 'https://www.facebook.com/geocache.wizard';
final ABOUT_LICENSE = 'GNU General Public License v3.0';
final ABOUT_LICENSE_URL = 'https://www.gnu.org/licenses/gpl-3.0.en.html';
final ABOUT_GITHUB = 'github.com/S-Man42/GCWizard';
final ABOUT_GITHUB_URL = 'https://github.com/S-Man42/GCWizard';
final ABOUT_PRIVACYPOLICY = 'legal.gcwizard.net/privacy_policy.html';
final ABOUT_PRIVACYPOLICY_URL = 'https://legal.gcwizard.net/privacy_policy.html';

class About extends StatefulWidget {
  @override
  AboutState createState() => AboutState();
}

class AboutState extends State<About> {

  var packageInfo = PackageInfo();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    var content = Column(
      children: <Widget>[
        Text(
          'GC Wizard - Geocache Wizard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize()),
        ),
        GCWDivider(),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                  text: i18n(context, 'about_version')
                ),
                flex: 2
              ),
              Expanded(
                child: GCWText(
                  text: '${packageInfo.version} (Build: ${packageInfo.buildNumber})'
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
            top: 15
          )
        ),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                  text: i18n(context, 'about_maintainer')
                ),
                flex: 2
              ),
              Expanded(
                child: GCWText(
                  text: ABOUT_MAINTAINER
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
            top: 15,
            bottom: 10
          )
        ),
        GCWDivider(),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                  text: i18n(context, 'about_contact_email')
                ),
                flex: 2
              ),
              Expanded(
                child: InkWell(
                  child: Text(
                    ABOUT_EMAIL,
                    style: gcwHyperlinkTextStyle(),
                  ),
                  onTap: () {
                    launch(ABOUT_EMAIL_URL);
                  },
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
            top: 15,
            bottom: 10
          )
        ),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                  text: i18n(context, 'about_website')
                ),
                flex: 2
              ),
              Expanded(
                child: InkWell(
                  child: Text(
                    ABOUT_WEBSITE,
                    style: gcwHyperlinkTextStyle(),
                  ),
                  onTap: () {
                    launch(ABOUT_WEBSITE_URL);
                  },
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
              top: 15,
              bottom: 10
          )
        ),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                    text: i18n(context, 'about_blog')
                ),
                flex: 2
              ),
              Expanded(
                child: InkWell(
                  child: Text(
                    ABOUT_BLOG,
                    style: gcwHyperlinkTextStyle(),
                  ),
                  onTap: () {
                    launch(ABOUT_BLOG_URL);
                  },
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
              top: 15,
              bottom: 10
          )
        ),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                  text: i18n(context, 'about_twitter')
                ),
                flex: 2
              ),
              Expanded(
                child: InkWell(
                  child: Text(
                    ABOUT_TWITTER,
                    style: gcwHyperlinkTextStyle(),
                  ),
                  onTap: () {
                    launch(ABOUT_TWITTER_URL);
                  },
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
            top: 15,
            bottom: 10
          )
        ),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                  text: i18n(context, 'about_facebook')
                ),
                flex: 2
              ),
              Expanded(
                child: InkWell(
                  child: Text(
                    ABOUT_FACEBOOK,
                    style: gcwHyperlinkTextStyle(),
                  ),
                  onTap: () {
                    launch(ABOUT_FACEBOOK_URL);
                  },
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
            top: 15,
            bottom: 10
          )
        ),
        GCWDivider(),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                  text: i18n(context, 'about_license')
                ),
                flex: 2
              ),
              Expanded(
                child: InkWell(
                  child: Text(
                    ABOUT_LICENSE,
                    style: gcwHyperlinkTextStyle(),
                  ),
                  onTap: () {
                    launch(ABOUT_LICENSE_URL);
                  },
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
            top: 15,
            bottom: 10
          )
        ),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                  text: i18n(context, 'about_github')
                ),
                flex: 2
              ),
              Expanded(
                child: InkWell(
                  child: Text(
                    ABOUT_GITHUB,
                    style: gcwHyperlinkTextStyle(),
                  ),
                  onTap: () {
                    launch(ABOUT_GITHUB_URL);
                  },
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
            top: 15,
            bottom: 10
          )
        ),
        GCWDivider(),
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: GCWText(
                    text: i18n(context, 'about_privacypolicy')
                ),
                flex: 2
              ),
              Expanded(
                child: InkWell(
                  child: Text(
                    ABOUT_PRIVACYPOLICY,
                    style: gcwHyperlinkTextStyle(),
                  ),
                  onTap: () {
                    launch(ABOUT_PRIVACYPOLICY_URL);
                  },
                ),
                flex: 3
              )
            ]
          ),
          padding: EdgeInsets.only(
              top: 15,
              bottom: 10
          )
        ),
        GCWDivider(),
        Container(
          child: Column(
            children: <Widget>[
              Text(
                i18n(context, 'about_thanks'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize()),
              ),
              Container(
                child: GCWText(
                  align: Alignment.center,
                  text: 'Daniel \'Eisbehr\' K. (Maintainer GCC)\n'
                ),
                padding: EdgeInsets.only(
                  top: 15,
                  bottom: 10
                )
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: i18n(context, 'about_specialsupport') + '\n',
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    TextSpan(
                      text: 'Andy \'Puma66\''
                        + '\n'
                    )
                  ],
                  style: TextStyle(fontSize: defaultFontSize())
                ),
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: i18n(context, 'about_contributors') + '\n',
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    TextSpan(
                      text:
                        [
                          '\'\xc4ggsb\xe4rde\' (Symbol Tables)',
                          '\'capoaira\' (Code)',
                          'Dennis \'dennistreysa\' (Code)',
                          '\'Geo-Link\' (Hardware & Symbol Tables)',
                          'Karl B. (Coords)',
                          'Michael D. (Symbol Tables)',
                          '\'moenk\' (GK Coords)',
                          'Stefan S. (Symbol Tables)',
                          'Udo J. (Code)',
                          '\'wollpirat\' (Food, Tea & more)'
                        ].join('\n') + '\n'
                    )
                  ],
                  style: TextStyle(fontSize: defaultFontSize())
                ),
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: i18n(context, 'about_testers') + '\n',
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    TextSpan(
                      text:
                        [
                          'Andreas E.',
                          '\'Headbanger-Berlin\'',
                          'Felix Z.',
                          '\'Filu - Aye, Käppn! - 43\' & \'Stormi - Aaarrh - 2061\'',
                          'Frank \'Wizardland\' (podKst.de)',
                          'Franz K.',
                          'Johannes C.',
                          '\'Klumpenkukuk\'',
                          '\'lupusmaximus\'',
                          '\'mahoplus\'',
                          'Martin Sch.',
                          '\'Schnatt\'',
                          'Palk \'geogedoens.de\'',
                          '\'Pamakaru\'',
                          'Paweł B.',
                          '\'radioscout\'',
                          '\'radlerandi\'',
                          '\'Sechsfüssler\'',
                          'Stefan J.',
                          '\'tebarius\'',
                          '\'tomcat06\'',
                        ].join(', ')
                    )
                  ],
                  style: TextStyle(fontSize: defaultFontSize())
                ),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 15,
            bottom: 10
          ),
        ),
        GCWDivider(),
        Container(
          child: GCWText(
            align: Alignment.center,
            textAlign: TextAlign.center,
            text: i18n(context, 'about_notfornazis')
          ),
          padding: EdgeInsets.only(
            top: 15,
            bottom: 10
          ),
        )

      ],
    );

    return GCWMainMenuEntryStub(
      content: content
    );
  }
}