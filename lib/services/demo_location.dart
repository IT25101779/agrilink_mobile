/// Position the app uses when the phone's GPS is off or permission is denied
/// (indoors at a venue, simulator, etc.).
///
/// Set to Battaramulla (Colombo) for the hackX final demo, so "nearby lorries",
/// "nearby suppliers" and community listings always show the Battaramulla demo
/// data even if GPS fails. To go back to Kandy: lat 7.2906, lng 80.6337.
/// (Approximate point near the Water's Edge area, Battaramulla.)
const double kFallbackLat = 6.8995;
const double kFallbackLng = 79.9190;
