import 'package:bicaraku/app/modules/reset_password/bindings/verify_code_binding.dart';
import 'package:bicaraku/app/modules/reset_password/controllers/create_password_controller.dart';
import 'package:bicaraku/app/modules/reset_password/views/create_password_view.dart';
import 'package:bicaraku/app/modules/reset_password/views/verify_code_view.dart';
import 'package:get/get.dart';

import '../modules/f1_looknhear/bindings/looknhear_binding.dart';
import '../modules/f1_looknhear/views/looknhear_detect_view.dart';
import '../modules/f1_looknhear/views/looknhear_view.dart';
import '../modules/f2_cariobjek/controllers/cariobjek_controller.dart';
import '../modules/f2_cariobjek/views/cariobjek_view.dart';
import '../modules/f2_cariobjek/views/cariobjekcam_view.dart';
import '../modules/f3_peoplespeak/views/peoplespeak_view.dart';
import '../modules/history_activity/bindings/history_activity_binding.dart';
import '../modules/history_activity/views/history_activity_view.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/home/views/history_view.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profil/bindings/profil_binding.dart';
import '../modules/profil/views/profil_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/reset_password/bindings/reset_password_binding.dart';
import '../modules/reset_password/views/reset_password_view.dart';
import '../modules/scraping/bindings/scraping_binding.dart';
import '../modules/scraping/views/scraping_view.dart';
import '../modules/screen/views/splash2_view.dart';
import '../modules/screen/views/splash3_view.dart';
import '../modules/screen/views/splash4_view.dart';
import '../modules/screen/views/splash5_view.dart';
import '../modules/screen/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    // SPLASH SCREEN
    GetPage(name: Routes.SPLASH, page: () => const SplashView()),
    GetPage(name: Routes.SPLASH2, page: () => const Splash2View()),
    GetPage(name: Routes.SPLASH3, page: () => const Splash3View()),
    GetPage(name: Routes.SPLASH4, page: () => const Splash4View()),
    GetPage(name: Routes.SPLASH5, page: () => const Splash5View()),

    // LOGIN
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    // RESET PASSWORD
    GetPage(
      name: Routes.RESET_PASSWORD,
      page: () => ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: Routes.VERIFY_CODE,
      page: () => const VerifyCodeView(),
      binding: VerifyCodeBinding(),
    ),
    GetPage(
      name: Routes.CREATE_PASSWORD,
      page: () => CreatePasswordView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CreatePasswordController());
      }),
    ),

    // REGISTER
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),

    // HOME
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    ),

    // PROFIL
    GetPage(
      name: Routes.PROFIL,
      page: () => ProfilView(),
      binding: ProfilBinding(),
    ),

    // LOOKNHEAR
    GetPage(
      name: '/looknhear',
      page: () => const LooknhearView(),
      binding: CariobjekBinding(),
    ),
    GetPage(name: '/looknhearcam', page: () => const LooknhearDetectView()),

    // CARIOBJEK
    GetPage(
      name: Routes.CARIOBJEK,
      page: () => const CariobjekView(),
    ),

    GetPage(
      name: Routes.CARIOBJEKCAM,
      page: () => CariobjekcamView(),
      binding: BindingsBuilder(() {
        final arguments = Get.arguments;
        Get.put(CariObjekController());

        // Jika ada instruksi dari history, set ke controller
        if (arguments != null && arguments is String) {
          Get.find<CariObjekController>().instruksi.value = arguments;
        }
      }),
    ),

    // PEOPLESPEAK
    GetPage(name: '/peoplespeak', page: () => PeopleSpeakView()),
    GetPage(
      name: Routes.SCRAPING,
      page: () => const ScrapingView(),
      binding: ScrapingBinding(),
    ),

    GetPage(name: Routes.HISTORY, page: () => const HistoryView()),
   
    GetPage(
      name: Routes.HISTORY_ACTIVITY,
      page: () => const HistoryActivityView(),
      binding: HistoryActivityBinding(),
    ),
  ];
}
