/// The three legal documents, transcribed from the designs.
///
/// Kept out of `AppStrings`/`AppTranslations` on purpose: those hold short
/// interface labels that both dictionaries must mirror, whereas these are
/// whole documents whose wording is a legal decision. Terms & Conditions ship
/// in Spanish exactly as the design does — translating them here would change
/// their meaning, which is not a UI change to make.
class LegalCopy {
  LegalCopy._();

  static const String aboutUs = '''
Tu bienestar. Bien simplificado.
Bienify is a digital health platform designed to make healthcare more accessible, connected, and convenient. Our goal is to bring essential healthcare services together in one easy-to-use platform—helping patients connect with healthcare professionals, manage prescriptions, access laboratory and radiology services, coordinate medications with participating pharmacies, and keep important health documents organized in one secure place.
With Bienify, patients can access features such as virtual medical consultations, digital prescriptions, medication ordering and delivery where available, laboratory and radiology requests, medical report uploads, and a centralized Medical Vault for their health information.
Our Mission
Our mission is to simplify access to healthcare through technology, creating a more connected experience between patients, healthcare professionals, pharmacies, laboratories, diagnostic centers, and other healthcare partners.
We believe healthcare should be easier to navigate—from the moment you need a doctor to the moment you receive your treatment and manage your ongoing health information.''';

  static const String terms = '''
BIENIFY
Última actualización: 7/21/26
Bienvenido a Bienify. Estos Términos y Condiciones regulan el acceso y uso de la aplicación móvil, sitio web y servicios tecnológicos ofrecidos a través de Bienify.
Al crear una cuenta, acceder o utilizar Bienify, usted declara haber leído, comprendido y aceptado estos Términos y Condiciones, así como nuestra Politica de Privacidad y los consentimientos aplicables.
1. Sobre Bienify
Bienify es una plataforma tecnológica de salud diseñada para facilitar el acceso a servicios relacionados con la atención médica, incluyendo, según disponibilidad:
 ·  Consultas médicas presenciales o mediante telemedicina.
 ·  Búsqueda y programación de citas con profesionales de salud.
 ·  Emisión y gestión de recetas médicas digitales.
 ·  Solicitudes de pruebas de laboratorio y estudios de radiología.
 ·  Carga, almacenamiento y consulta de documentos médicos.
 ·  Conexión con farmacias y otros proveedores participantes.
 ·  Solicitud y seguimiento de medicamentos para entrega o recogida.
 ·  Procesamiento de pagos.
 ·  Comunicación entre pacientes y profesionales o proveedores participantes.
Salvo cuando se indique expresamente lo contrario, Bienify funciona como una plataforma tecnológica que facilita la conexión entre usuarios y proveedores independientes de servicios de salud.
Los médicos, farmacias, laboratorios, centros de diagnóstico, servicios de entrega y demás proveedores participantes pueden ser entidades independientes responsables de los servicios que prestan.
2. Bienify no es un servicio de emergencias
Bienify no presta servicios de urgencias ni atención de emergencia. Si usted considera que enfrenta una emergencia médica, comuníquese de inmediato con los servicios de emergencia locales.''';

  static const String privacy = '''
Effective Date: 7/21/26
Bienify (“Bienify,” “we,” “our,” or “us”) respects your privacy and is committed to protecting your personal, medical, and other confidential information.
This Privacy Policy explains how information is collected, used, stored, disclosed, and protected when you use the Bienify mobile application, website, telemedicine services, pharmacy services, laboratory and radiology features, medication delivery services, and related services (collectively, the “Platform”).
By creating an account or using Bienify, you acknowledge the practices described in this Privacy Policy.
1. Information We Collect
Depending on how you use Bienify, we may collect information including:
Personal information, such as your name, date of birth, telephone number, email address, gender where relevant to care, address, profile photograph, and identity-verification information.
Health and medical information, which may include symptoms, medical history, allergies, medications, diagnoses, treatment information, consultation records, prescriptions, laboratory orders and results, radiology orders and reports, documents uploaded by you, and communications with healthcare professionals.
Account information, including login credentials, account preferences, language preferences, and account activity.
Transaction and payment information, including information necessary to process consultation payments, pharmacy purchases, delivery charges, refunds, and other transactions. Payment-card information may be processed by authorized third-party payment processors rather than stored directly by Bienify.
Location and delivery information, including delivery addresses and, when enabled and necessary, approximate or precise location information used to identify nearby healthcare providers, pharmacies, laboratories, imaging centers, or facilitate medication delivery.''';
}
