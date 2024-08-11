class ProfileAssets {
  // Normal Profile Images
  static const String normalProfileCat1 = 'lib/assets/profile_image_assets/normal_profile_images/cat_1_profile_image.png';
  static const String normalProfileCow = 'lib/assets/profile_image_assets/normal_profile_images/cow_profile_image.png';
  static const String normalProfileCub1 = 'lib/assets/profile_image_assets/normal_profile_images/cub_1_profile_image.png';
  static const String normalProfileDog = 'lib/assets/profile_image_assets/normal_profile_images/dog_profile_image.png';

  // Normal Backgrounds
  static const String normalBackgroundFlower = 'lib/assets/profile_image_assets/normal_background/flower_bg.png';
  static const String normalBackgroundTemperateWoodland = 'lib/assets/profile_image_assets/normal_background/temperate_woodland_bg.png';
  static const String normalBackgroundTropicalDryForest = 'lib/assets/profile_image_assets/normal_background/tropical_dry_forest_bg.png';
  static const String normalBackgroundTropicalRainForest = 'lib/assets/profile_image_assets/normal_background/tropical_rain_forest_bg.png';

  // Premium Profile Images
  static const String premiumProfileCat2 = 'lib/assets/profile_image_assets/premium_profile_images/cat_2_profile_image.png';
  static const String premiumProfileCrab = 'lib/assets/profile_image_assets/premium_profile_images/crab_profile_image.png';
  static const String premiumProfileCub2 = 'lib/assets/profile_image_assets/premium_profile_images/cub_2_profile_image.png';
  static const String premiumProfileDuck = 'lib/assets/profile_image_assets/premium_profile_images/duck_profile_image.png';
  static const String premiumProfileFlamingo = 'lib/assets/profile_image_assets/premium_profile_images/flamingo_profile_image.png';
  static const String premiumProfileFrog = 'lib/assets/profile_image_assets/premium_profile_images/frog_profile_image.png';
  static const String premiumProfileGreyWolf = 'lib/assets/profile_image_assets/premium_profile_images/grey_wolf_profile_image.png';
  static const String premiumProfileLion = 'lib/assets/profile_image_assets/premium_profile_images/lion_profile_image.png';
  static const String premiumProfileSwan = 'lib/assets/profile_image_assets/premium_profile_images/swan_profile_image.png';
  static const String premiumProfileWhiteWolf = 'lib/assets/profile_image_assets/premium_profile_images/white_wolf_profile_image.png';

  // Premium Backgrounds
  static const String premiumBackgroundBeach = 'lib/assets/profile_image_assets/premium_backgrounds/beach_bg.png';
  static const String premiumBackgroundDesert = 'lib/assets/profile_image_assets/premium_backgrounds/desert_bg.png';
  static const String premiumBackgroundReef = 'lib/assets/profile_image_assets/premium_backgrounds/reef_bg.png';
  static const String premiumBackgroundTide = 'lib/assets/profile_image_assets/premium_backgrounds/tide_bg.png';
  static const String premiumBackgroundTropicalSavanna = 'lib/assets/profile_image_assets/premium_backgrounds/tropical_savanna_bg.png';
  static const String premiumBackgroundTundra = 'lib/assets/profile_image_assets/premium_backgrounds/tundra_bg.png';

  // Special Profile Images
  static const String specialProfileBlackPanther = 'lib/assets/profile_image_assets/special_profile_images/black_panther_profile_image.png';
  static const String specialProfileBlackWolf = 'lib/assets/profile_image_assets/special_profile_images/black_wolf_profile_image.png';
  static const String specialProfileOrangeWolf = 'lib/assets/profile_image_assets/special_profile_images/orange_wolf_profile_image.png';
  static const String specialProfileTiger = 'lib/assets/profile_image_assets/special_profile_images/tiger_profile_image.png';

  // Special Backgrounds
  static const String specialBackgroundCloud = 'lib/assets/profile_image_assets/special_background/cloud_bg.png';
  static const String specialBackgroundMountain = 'lib/assets/profile_image_assets/special_background/mountain_bg.png';

  // Getters
  static Map<String, String> get normalProfileImages => {
    'Normal Cat': normalProfileCat1,
    'Cow': normalProfileCow,
    'Cub': normalProfileCub1,
    'Dog': normalProfileDog,
  };

  static Map<String, String> get premiumProfileImages => {
    'Premium Cat': premiumProfileCat2,
    'Crab': premiumProfileCrab,
    'Premium Cub': premiumProfileCub2,
    'Duck': premiumProfileDuck,
    'Flamingo': premiumProfileFlamingo,
    'Frog': premiumProfileFrog,
    'Grey Wolf': premiumProfileGreyWolf,
    'Lion': premiumProfileLion,
    'Swan': premiumProfileSwan,
    'White Wolf': premiumProfileWhiteWolf,
  };

  static Map<String, String> get specialProfileImages => {
    'Black Panther': specialProfileBlackPanther,
    'Black Wolf': specialProfileBlackWolf,
    'Orange Wolf': specialProfileOrangeWolf,
    'Tiger': specialProfileTiger,
  };

  static Map<String, String> get normalBackgrounds => {
    'Flower Background': normalBackgroundFlower,
    'Temperate Woodland Background': normalBackgroundTemperateWoodland,
    'Tropical Dry Forest Background': normalBackgroundTropicalDryForest,
    'Tropical Rain Forest Background': normalBackgroundTropicalRainForest,
  };

  static Map<String, String> get premiumBackgrounds => {
    'Beach Background': premiumBackgroundBeach,
    'Desert Background': premiumBackgroundDesert,
    'Reef Background': premiumBackgroundReef,
    'Tide Background': premiumBackgroundTide,
    'Tropical Savanna Background': premiumBackgroundTropicalSavanna,
    'Tundra Background': premiumBackgroundTundra,
  };

  static Map<String, String> get specialBackgrounds => {
    'Cloud Background': specialBackgroundCloud,
    'Mountain Background': specialBackgroundMountain,
  };

  // Map asset IDs to their paths for strings
  static const Map<String, String> _assetPaths = {
    // Normal Profile Images
    'Normal Cat': normalProfileCat1,
    'Cow': normalProfileCow,
    'Cub': normalProfileCub1,
    'Dog': normalProfileDog,

    // Premium Profile Images
    'Premium Cat': premiumProfileCat2,
    'Crab': premiumProfileCrab,
    'Premium Cub': premiumProfileCub2,
    'Duck': premiumProfileDuck,
    'Flamingo': premiumProfileFlamingo,
    'Frog': premiumProfileFrog,
    'Grey Wolf': premiumProfileGreyWolf,
    'Lion': premiumProfileLion,
    'Swan': premiumProfileSwan,
    'White Wolf': premiumProfileWhiteWolf,

    // Special Profile Images
    'Black Panther': specialProfileBlackPanther,
    'Black Wolf': specialProfileBlackWolf,
    'Orange Wolf': specialProfileOrangeWolf,
    'Tiger': specialProfileTiger,

    // Normal Backgrounds
    'Flower Background': normalBackgroundFlower,
    'Temperate Woodland Background': normalBackgroundTemperateWoodland,
    'Tropical Dry Forest Background': normalBackgroundTropicalDryForest,
    'Tropical Rain Forest Background': normalBackgroundTropicalRainForest,

    // Premium Backgrounds
    'Beach Background': premiumBackgroundBeach,
    'Desert Background': premiumBackgroundDesert,
    'Reef Background': premiumBackgroundReef,
    'Tide Background': premiumBackgroundTide,
    'Tropical Savanna Background': premiumBackgroundTropicalSavanna,
    'Tundra Background': premiumBackgroundTundra,

    // Special Backgrounds
    'Cloud Background': specialBackgroundCloud,
    'Mountain Background': specialBackgroundMountain,
  };

  // Get the asset path by ID
  static String getAssetPath(String id) {
    return _assetPaths[id] ?? '';
  }
}
