//
//  SMVoiceManager.m
//  Speind
//
//  Created by Sergey Butenko on 9/2/14.
//  Copyright (c) 2014 serejahh inc. All rights reserved.
//

#import "SMVoiceManager.h"
#import "SMSettings.h"

@interface SMVoiceManager ()

/**
 * Описание элементов по порядку: 1 - язык голоса; 2 - заголовок голоса для отображения в списке; 3 - имя диктора; 4 - локаль голоса; 5 - статус покупки голоса, по умолчанию все голоса не куплены и не скачаны; 6 - ссылка на демо голоса.
 */
@property (nonatomic) NSArray *rawVoices;

/**
 * Имена голосов, один из которых можно скачать беплатно.
 */
@property (nonatomic) NSArray *freeVoiceNames;

/**
 * Key - name of voice, value - link to archive of voice. For downloading used URN: "voices/"
 */
@property (nonatomic) NSDictionary *links;

@end

@implementation SMVoiceManager

#pragma mark - Public API

+ (instancetype)sharedManager
{
    static SMVoiceManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (NSArray*)availableLanguages
{
    NSMutableSet *languages = [NSMutableSet set];
    
    for (SMVoice *voice in self.voices) {
        [languages addObject:voice.lang];
    }
        
    return [languages.allObjects sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSArray*)voicesForLanguage:(NSString*)language
{
    NSMutableArray *voices = [NSMutableArray array];
    [voices addObject:[SMVoice nativeVoiceForLang:language]];
    
    NSArray *inavailableToPurchase = [[SMSettings sharedSettings] inavailableProducts];
    for (SMVoice *voice in self.voices) {
        if ([voice.lang isEqualToString:language] && ![inavailableToPurchase containsObject:voice.productID]) {
            [voices addObject:voice];
        }
    }
    
    return voices;
}

- (NSArray*)freeVoices
{
    NSMutableArray *freeVoices = [NSMutableArray array];
    NSArray *allVoices = [self voices];
    
    for (SMVoice *voice in allVoices) {
        if ([self.freeVoiceNames containsObject:voice.name]) {
            [freeVoices addObject:voice];
        }
    }
    
    return [freeVoices copy];
}

#pragma mark - Lazy instantiation

- (NSArray *)voices
{
    if (!_voices) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (NSArray *voice in self.rawVoices) {
            SMVoice *v = [SMVoice voiceWithLang:voice[0] title:voice[1] name:voice[2] locale:voice[3] demo:voice[5] link:@""];
            v.link = [self.links objectForKey:v.name];
            [tmp addObject:v];
        }
        _voices = [tmp copy];
    }
    
    return _voices;
}

- (NSArray *)freeVoiceNames
{
    if (!_freeVoiceNames) {
        _freeVoiceNames = @[@"Alyona", @"Peter", @"Julie", @"Antonio"];
    }
    return _freeVoiceNames;
}

- (NSArray *)rawVoices
{
    if (!_rawVoices) {
        _rawVoices = @[
                       //@[@"bokmål", @"Bente",  @"Bente", @"nb", @"0", @"non_bente_22k_ns.qvcu.mp3"],
                       //@[@"bokmål", @"Kari", @"Kari", @"nb", @"0", @"non_kari_22k_ns.qvcu.mp3"],
                       //@[@"bokmål", @"Olav", @"Olav", @"nb", @"0", @"non_olav_22k_ns.qvcu.mp3"],
                       //@[@"Brazilian", @"Marcia",  @"Marcia", @"br", @"0", @"pob_marcia_22k_ns.qvcu.mp3"],
                       //@[@"català", @"Laia", @"Laia", @"ca", @"0", @"ca_es_laia_22k_ns.qvcu.mp3"],
                       //@[@"čeština", @"Eliska",  @"Eliska", @"cz", @"0", @"czc_eliska_22k_ns.qvcu.mp3"],
                       //@[@"Dansk", @"Mette",  @"Mette", @"da", @"0", @"dad_mette_22k_ns.qvcu.mp3"],
                       //@[@"Dansk", @"Rasmus",  @"Rasmus", @"da", @"0", @"dad_rasmus_22k_ns.qvcu.mp3"],
                       //@[@"Deutsch", @"Andreas",  @"Andreas", @"de", @"0", @"ged_andreas_22k_ns.qvcu.mp3"],
                       //@[@"Deutsch", @"Julia",  @"Julia", @"de", @"0", @"ged_julia_22k_ns.qvcu.mp3"],
                       //@[@"Deutsch", @"Klaus",  @"Klaus", @"de", @"0", @"ged_klaus_22k_ns.qvcu.mp3"],
                       //@[@"Deutsch", @"Sarah",  @"Sarah", @"de", @"0", @"ged_sarah_22k_ns.qvcu.mp3"],
                       //@[@"English", @"Lisa [AustralianEnglish]",  @"Lisa", @"en", @"0", @"en_au_lisa_22k_ns.qvcu.mp3"],
                       //@[@"English", @"Tyler [AustralianEnglish]", @"Tyler", @"en", @"0", @"en_au_tyler_22k_ns.qvcu.mp3"],
                       @[@"English", @"Graham [British]", @"Graham", @"en", @"0", @"eng_graham_22k_ns.qvcu.mp3"],
                       @[@"English", @"Lucy [British]", @"Lucy", @"en", @"0", @"eng_lucy_22k_ns.qvcu.mp3"],
                       @[@"English", @"Nizar eng [British]", @"Nizareng", @"en", @"0", @"eng_nizareng_22k_ns.qvcu.mp3"],
                       @[@"English", @"Peter [British]", @"Peter", @"en", @"0", @"eng_peter_22k_ns.qvcu.mp3"],
                       @[@"English", @"Peter Happy [British]",  @"Peterhappy",  @"en", @"0", @"eng_peterhappy_22k_ns.qvcu.mp3"],
                       @[@"English", @"Peter Sad [British]", @"Petersad", @"en", @"0", @"eng_petersad_22k_ns.qvcu.mp3"],
                       @[@"English", @"Queen Elizabeth [British]", @"Queenelizabeth", @"en", @"0", @"eng_queenelizabeth_22k_ns.qvcu.mp3"],
                       @[@"English", @"Rachel [British]", @"Rachel", @"en", @"0", @"eng_rachel_22k_ns.qvcu.mp3"],
                       //@[@"English", @"Deepa [IndianEnglish]",  @"Deepa", @"en", @"0", @"en_in_deepa_22k_ns.qvcu.mp3"],
                       @[@"English", @"Heather [USEnglish]", @"Heather", @"en", @"0", @"enu_heather_22k_ns.qvcu.mp3"],
                       @[@"English", @"Karen [USEnglish]", @"Karen", @"en", @"0", @"enu_karen_22k_ns.qvcu.mp3"],
                       @[@"English", @"Kenny [USEnglish]", @"Kenny", @"en", @"0", @"enu_kenny_22k_ns.qvcu.mp3"],
                       @[@"English", @"Laura [USEnglish]", @"Laura", @"en", @"0", @"enu_laura_22k_ns.qvcu.mp3"],
                       @[@"English", @"Micah [USEnglish]", @"Micah", @"en", @"0", @"enu_micah_22k_ns.qvcu.mp3"],
                       @[@"English", @"Nelly [USEnglish]", @"Nelly", @"en", @"0", @"enu_nelly_22k_ns.qvcu.mp3"],
                       @[@"English", @"Ryan [USEnglish]", @"Ryan", @"en", @"0", @"enu_ryan_22k_ns.qvcu.mp3"],
                       @[@"English", @"Saul [USEnglish]", @"Saul", @"en", @"0", @"enu_saul_22k_ns.qvcu.mp3"],
                       @[@"English", @"Tracy [USEnglish]", @"Tracy", @"en", @"0", @"enu_tracy_22k_ns.qvcu.mp3"],
                       @[@"English", @"Will [USEnglish]", @"Will", @"en", @"0", @"enu_will_22k_ns.qvcu.mp3"],
                       @[@"English", @"Will Bad-guy [USEnglish]",  @"Willbadguy",  @"en", @"0", @"enu_willbadguy_22k_ns.qvcu.mp3"],
                       @[@"English", @"Will Aloud [USEnglish]",  @"Willfromafar",  @"en", @"0", @"enu_willfromafar_22k_ns.qvcu.mp3"],
                       @[@"English", @"Will Happy [USEnglish]",  @"Willhappy",  @"en", @"0", @"enu_willhappy_22k_ns.qvcu.mp3"],
                       @[@"English", @"Will Little Creature [USEnglish]", @"Willlittlecreature", @"en", @"0", @"enu_willlittlecreature_22k_ns.qvcu.mp3"],
                       @[@"English", @"Will Old Man [USEnglish]",  @"Willoldman",  @"en", @"0", @"enu_willoldman_22k_ns.qvcu.mp3"],
                       @[@"English", @"Will Sad [USEnglish]", @"Willsad", @"en", @"0", @"enu_willsad_22k_ns.qvcu.mp3"],
                       @[@"English", @"Will Close [USEnglish]",  @"Willupclose",  @"en", @"0", @"enu_willupclose_22k_ns.qvcu.mp3"],
                       @[@"Español", @"Antonio",  @"Antonio", @"es", @"0", @"sps_antonio_22k_ns.qvcu.mp3"],
                       @[@"Español", @"Ines", @"Ines", @"es", @"0", @"sps_ines_22k_ns.qvcu.mp3"],
                       @[@"Español", @"Maria",  @"Maria", @"es", @"0", @"sps_maria_22k_ns.qvcu.mp3"],
                       @[@"Español", @"Rosa [USSpanish]", @"Rosa", @"es", @"0", @"spu_rosa_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Alice",  @"Alice", @"fr", @"0", @"frf_alice_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Antonie",  @"Antoine", @"fr", @"0", @"frf_antoine_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Antoine Aloud", @"Antoinefromafar", @"fr", @"0", @"frf_antoinefromafar_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Antoine Happy", @"Antoinehappy",  @"fr", @"0", @"frf_antoinehappy_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Antoine Sad", @"Antoinesad",  @"fr", @"0", @"frf_antoinesad_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Antoine Close", @"Antoineupclose", @"fr", @"0", @"frf_antoineupclose_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Bruno",  @"Bruno", @"fr", @"0", @"frf_bruno_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Claire",  @"Claire", @"fr", @"0", @"frf_claire_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Julie",  @"Julie", @"fr", @"0", @"frf_julie_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Margaux",  @"Margaux", @"fr", @"0", @"frf_margaux_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Margaux Happy", @"Margauxhappy",  @"fr", @"0", @"frf_margauxhappy_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Margaux Sad", @"Margauxsad",  @"fr", @"0", @"frf_margauxsad_22k_ns.qvcu.mp3"],
                       @[@"Français", @"Robot",  @"Robot", @"fr", @"0", @"frf_robot_22k_ns.qvcu.mp3"],
                       //@[@"Français", @"Louise [CanadianFrench]",  @"Louise", @"fr", @"0", @"frc_louise_22k_ns.qvcu.mp3"],
                       //@[@"italiano", @"Chiara",  @"Chiara", @"it", @"0", @"iti_chiara_22k_ns.qvcu.mp3"],
                       //@[@"italiano", @"Fabiana",  @"Fabiana", @"it", @"0", @"iti_fabiana_22k_ns.qvcu.mp3"],
                       //@[@"italiano", @"Vittorio",  @"Vittorio", @"it", @"0", @"iti_vittorio_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Jeroen [BelgianDutch]",  @"Jeroen", @"nl", @"0", @"dub_jeroen_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Jeroen Happy [BelgianDutch]", @"Jeroenhappy",  @"nl", @"0", @"dub_jeroenhappy_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Jeroen Sad [BelgianDutch]", @"Jeroensad",  @"nl", @"0", @"dub_jeroensad_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Sofie [BelgianDutch]", @"Sofie", @"nl", @"0", @"dub_sofie_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Zoe [BelgianDutch]", @"Zoe", @"nl", @"0", @"dub_zoe_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Daan", @"Daan", @"nl", @"0", @"dun_daan_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Femke",  @"Femke", @"nl", @"0", @"dun_femke_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Jasmin",  @"Jasmijn", @"nl", @"0", @"dun_jasmijn_22k_ns.qvcu.mp3"],
                       //@[@"Nederlands", @"Max", @"Max", @"nl", @"0", @"dun_max_22k_ns.qvcu.mp3"],
                       //@[@"polski", @"Ania", @"Ania", @"pl", @"0", @"pop_ania_22k_ns.qvcu.mp3"],
                       //@[@"polski", @"Monika",  @"Monika", @"pl", @"0", @"pop_monika_22k_ns.qvcu.mp3"],
                       //@[@"Português", @"Celia",  @"Celia", @"pt", @"0", @"poe_celia_22k_ns.qvcu.mp3"],
                       //@[@"Scanian", @"Mia", @"Mia", @"snl", @"0", @"sc_se_mia_22k_ns.qvcu.mp3"],
                       //@[@"suomi", @"Sanna",  @"Sanna", @"fi", @"0", @"fif_sanna_22k_ns.qvcu.mp3"],
                       //@[@"svenska", @"Samuel [FinlandSwedish]",  @"Samuel", @"se", @"0", @"sv_fi_samuel_22k_ns.qvcu.mp3"],
                       //@[@"svenska", @"Kal [GothenburgSwedish]",  @"Kal", @"se", @"0", @"gb_se_kal_22k_ns.qvcu.mp3"],
                       //@[@"svenska", @"Elin", @"Elin", @"se", @"0", @"sws_elin_22k_ns.qvcu.mp3"],
                       //@[@"svenska", @"Emil", @"Emil", @"se", @"0", @"sws_emil_22k_ns.qvcu.mp3"],
                       //@[@"svenska", @"Emma", @"Emma", @"se", @"0", @"sws_emma_22k_ns.qvcu.mp3"],
                       //@[@"svenska", @"Erik", @"Erik", @"se", @"0", @"sws_erik_22k_ns.qvcu.mp3"],
                       //@[@"Türkçe", @"Ipek", @"Ipek", @"tr", @"0", @"tut_ipek_22k_ns.qvcu.mp3"],
                       //@[@"ελληνικά", @"Dimitris",  @"Dimitris", @"gr", @"0", @"grg_dimitris_22k_ns.qvcu.mp3"],
                       //@[@"ελληνικά", @"Dimitris Happy", @"DimitrisHappy", @"gr", @"0", @"grg_dimitrishappy_22k_ns.qvcu.mp3"],
                       //@[@"ελληνικά", @"Dimitris Sad", @"DimitrisSad",  @"gr", @"0", @"grg_dimitrissad_22k_ns.qvcu.mp3"],
                       @[@"Русский", @"Алёна",  @"Alyona", @"ru", @"0", @"rur_alyona_22k_ns.qvcu.mp3"],
                       //w @[@"ﺔﻴﺐﺮﻌﻠﺍ", @"Leila", @"Leila", @"ar", @"0", @"ar_sa_leila_22k_ns.qvcu.mp3"],
                       //w @[@"ﺔﻴﺐﺮﻌﻠﺍ", @"Mehdi", @"Mehdi", @"ar", @"0", @"ar_sa_mehdi_22k_ns.qvcu.mp3"],
                       //w @[@"ﺔﻴﺐﺮﻌﻠﺍ", @"Nizar", @"Nizar", @"ar", @"0", @"ar_sa_nizar_22k_ns.qvcu.mp3"],
                       //w @[@"ﺔﻴﺐﺮﻌﻠﺍ", @"Salma", @"Salma", @"ar", @"0", @"ar_sa_salma_22k_ns.qvcu.mp3"],
                       //@[@"한국어", @"Minji", @"Minji", @"kr", @"0", @"ko_kr_minji_22k_ns.qvcu.mp3"],
                       //@[@"中文", @"Lulu [MandarinChinese]", @"Lulu", @"cn", @"0", @"zh_cn_lulu_22k_ns.qvcu.mp3"],
                       //@[@"日本語", @"Sakura", @"Sakura", @"jp", @"0", @"ja_jp_sakura_22k_ns.qvcu.mp3"]
                       ];
    }
    return _rawVoices;
}

- (NSDictionary *)links
{
    if (!_links) {
        _links = @{
                   @"Bente" : @"hq-ref-Norwegian-Bente-22khz.zip",
                   @"Kari" : @"hq-ref-Norwegian-Kari-22khz.zip",
                   @"Olav" : @"hq-ref-Norwegian-Olav-22khz.zip",
                   @"Marcia" : @"hq-ref-Brazilian-Marcia-22khz.zip",
                   @"Laia" : @"hq-ref-Catalan-Laia-22khz.zip",
                   @"Eliska" : @"hq-ref-Czech-Eliska-22khz.zip",
                   @"Mette" : @"hq-ref-Danish-Mette-22khz.zip",
                   @"Rasmus" : @"hq-ref-Danish-Rasmus-22khz.zip",
                   @"Andreas" : @"hq-ref-German-Andreas-22khz.zip",
                   @"Julia" : @"hq-ref-German-Julia-22khz.zip",
                   @"Klaus" : @"hq-ref-German-Klaus-22khz.zip",
                   @"Sarah" : @"hq-ref-German-Sarah-22khz.zip",
                   @"Lisa" : @"hq-ref-AustralianEnglish-Lisa-22khz.zip",
                   @"Tyler" : @"hq-ref-AustralianEnglish-Tyler-22khz.zip",
                   @"Graham" : @"hq-ref-British-Graham-22khz.zip",
                   @"Lucy" : @"hq-ref-British-Lucy-22khz.zip",
                   @"Nizareng" : @"hq-ref-British-Nizareng-22khz.zip",
                   @"Peter" : @"hq-ref-British-Peter-22khz.zip",
                   @"Peterhappy" : @"hq-ref-British-Peterhappy-22khz.zip",
                   @"Petersad" : @"hq-ref-British-Petersad-22khz.zip",
                   @"Queenelizabeth" : @"hq-ref-British-Queenelizabeth-22khz.zip",
                   @"Rachel" : @"hq-ref-British-Rachel-22khz.zip",
                   @"Deepa" : @"hq-ref-IndianEnglish-Deepa-22khz.zip",
                   @"Heather" : @"hq-ref-USEnglish-Heather-22khz.zip",
                   @"Karen" : @"hq-ref-USEnglish-Karen-22khz.zip",
                   @"Kenny" : @"hq-ref-USEnglish-Kenny-22khz.zip",
                   @"Laura" : @"hq-ref-USEnglish-Laura-22khz.zip",
                   @"Micah" : @"hq-ref-USEnglish-Micah-22khz.zip",
                   @"Nelly" : @"hq-ref-USEnglish-Nelly-22khz.zip",
                   @"Ryan" : @"hq-ref-USEnglish-Ryan-22khz.zip",
                   @"Saul" : @"hq-ref-USEnglish-Saul-22khz.zip",
                   @"Tracy" : @"hq-ref-USEnglish-Tracy-22khz.zip",
                   @"Will" : @"hq-ref-USEnglish-Will-22khz.zip",
                   @"Willbadguy" : @"hq-ref-USEnglish-Willbadguy-22khz.zip",
                   @"Willfromafar" : @"hq-ref-USEnglish-Willfromafar-22khz.zip",
                   @"Willhappy" : @"hq-ref-USEnglish-Willhappy-22khz.zip",
                   @"Willlittlecreature" : @"hq-ref-USEnglish-Willlittlecreature-22khz.zip",
                   @"Willoldman" : @"hq-ref-USEnglish-Willoldman-22khz.zip",
                   @"Willsad" : @"hq-ref-USEnglish-Willsad-22khz.zip",
                   @"Willupclose" : @"hq-ref-USEnglish-Willupclose-22khz.zip",
                   @"Antonio" : @"hq-ref-Spanish-Antonio-22khz.zip",
                   @"Ines" : @"hq-ref-Spanish-Ines-22khz.zip",
                   @"Maria" : @"hq-ref-Spanish-Maria-22khz.zip",
                   @"Rosa" : @"hq-ref-USSpanish-Rosa-22khz.zip",
                   @"Alice" : @"hq-ref-French-Alice-22khz.zip",
                   @"Antoine" : @"hq-ref-French-Antoine-22khz.zip",
                   @"Antoinefromafar" : @"hq-ref-French-Antoinefromafar-22khz.zip",
                   @"Antoinehappy" : @"hq-ref-French-Antoinehappy-22khz.zip",
                   @"Antoinesad" : @"hq-ref-French-Antoinesad-22khz.zip",
                   @"Antoineupclose" : @"hq-ref-French-Antoineupclose-22khz.zip",
                   @"Bruno" : @"hq-ref-French-Bruno-22khz.zip",
                   @"Claire" : @"hq-ref-French-Claire-22khz.zip",
                   @"Julie" : @"hq-ref-French-Julie-22khz.zip",
                   @"Margaux" : @"hq-ref-French-Margaux-22khz.zip",
                   @"Margauxhappy" : @"hq-ref-French-Margauxhappy-22khz.zip",
                   @"Margauxsad" : @"hq-ref-French-Margauxsad-22khz.zip",
                   @"Robot" : @"hq-ref-French-Robot-22khz.zip",
                   @"Louise" : @"hq-ref-CanadianFrench-Louise-22khz.zip",
                   @"Chiara" : @"hq-ref-Italian-Chiara-22khz.zip",
                   @"Fabiana" : @"hq-ref-Italian-Fabiana-22khz.zip",
                   @"Vittorio" : @"hq-ref-Italian-Vittorio-22khz.zip",
                   @"Jeroen" : @"hq-ref-BelgianDutch-Jeroen-22khz.zip",
                   @"Jeroenhappy" : @"hq-ref-BelgianDutch-Jeroenhappy-22khz.zip",
                   @"Jeroensad" : @"hq-ref-BelgianDutch-Jeroensad-22khz.zip",
                   @"Sofie" : @"hq-ref-BelgianDutch-Sofie-22khz.zip",
                   @"Zoe" : @"hq-ref-BelgianDutch-Zoe-22khz.zip",
                   @"Daan" : @"hq-ref-Dutch-Daan-22khz.zip",
                   @"Femke" : @"hq-ref-Dutch-Femke-22khz.zip",
                   @"Jasmijn" : @"hq-ref-Dutch-Jasmijn-22khz.zip",
                   @"Max" : @"hq-ref-Dutch-Max-22khz.zip",
                   @"Ania" : @"hq-ref-Polish-Ania-22khz.zip",
                   @"Monika" : @"hq-ref-Polish-Monika-22khz.zip",
                   @"Celia" : @"hq-ref-Portuguese-Celia-22khz.zip",
                   @"Mia" : @"hq-ref-Scanian-Mia-22khz.zip",
                   @"Sanna" : @"hq-ref-Finnish-Sanna-22khz.zip",
                   @"Samuel" : @"hq-ref-FinlandSwedish-Samuel-22khz.zip",
                   @"Kal" : @"hq-ref-GothenburgSwedish-Kal-22khz.zip",
                   @"Elin" : @"hq-ref-Swedish-Elin-22khz.zip",
                   @"Emil" : @"hq-ref-Swedish-Emil-22khz.zip",
                   @"Emma" : @"hq-ref-Swedish-Emma-22khz.zip",
                   @"Erik" : @"hq-ref-Swedish-Erik-22khz.zip",
                   @"Ipek" : @"hq-ref-Turkish-Ipek-22khz.zip",
                   @"Dimitris" : @"hq-ref-Greek-Dimitris-22khz.zip",
                   @"DimitrisHappy" : @"hq-ref-Greek-DimitrisHappy-22khz.zip",
                   @"DimitrisSad" : @"hq-ref-Greek-DimitrisSad-22khz.zip",
                   @"Alyona" : @"hq-ref-Russian-Alyona-22khz.zip",
                   @"Leila" : @"hq-ref-Arabic-Leila-22khz.zip",
                   @"Mehdi" : @"hq-ref-Arabic-Mehdi-22khz.zip",
                   @"Nizar" : @"hq-ref-Arabic-Nizar-22khz.zip",
                   @"Salma" : @"hq-ref-Arabic-Salma-22khz.zip",
                   @"Minji" : @"hq-ref-Korean-Minji-22khz.zip",
                   @"Lulu" : @"hq-ref-MandarinChinese-Lulu-22khz.zip",
                   @"Sakura" : @"hq-ref-Japanese-Sakura-22khz.zip"
                   };
    }
    return _links;
}

@end
