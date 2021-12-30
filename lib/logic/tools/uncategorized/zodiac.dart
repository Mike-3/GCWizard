const ZODIACSIGNS_ATTRIBUTE_DATE = 'zodiac_attribute_date';
const ZODIACSIGNS_ATTRIBUTE_HOUSE = 'zodiac_attribute_house';
const ZODIACSIGNS_ATTRIBUTE_ELEMENT = 'zodiac_attribute_element';
const ZODIACSIGNS_ATTRIBUTE_QUALITY = 'zodiac_attribute_quality';
const ZODIACSIGNS_ATTRIBUTE_POLARITY = 'zodiac_attribute_polarity';
const ZODIACSIGNS_ATTRIBUTE_PLANET = 'zodiac_attribute_planet';

const ZODIACSIGNS_ATTRIBUTES = [
  ZODIACSIGNS_ATTRIBUTE_DATE,
  ZODIACSIGNS_ATTRIBUTE_PLANET,
  ZODIACSIGNS_ATTRIBUTE_ELEMENT,
  ZODIACSIGNS_ATTRIBUTE_HOUSE,
  ZODIACSIGNS_ATTRIBUTE_QUALITY,
  ZODIACSIGNS_ATTRIBUTE_POLARITY,
];

const ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_EARTH = 'symboltables_alchemy_earth';
const ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_FIRE = 'symboltables_alchemy_fire';
const ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_WATER = 'symboltables_alchemy_water';
const ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_AIR = 'symboltables_alchemy_air';

const ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_MASCULINE = 'zodiac_attribute_polarity_masculine';
const ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_FEMININE = 'zodiac_attribute_polarity_feminine';

const ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_CARDINAL = 'zodiac_attribute_quality_cardinal';
const ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_FIXED = 'zodiac_attribute_quality_fixed';
const ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_MUTABLE = 'zodiac_attribute_quality_mutable';

const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_MARS = 'symboltables_planets_mars';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_MERCURY = 'symboltables_planets_mercury';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_VENUS = 'symboltables_planets_venus';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_MOON = 'coords_ellipsoid_moon';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_SUN = 'symboltables_planets_sun';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_CHIRON = 'symboltables_planets_chiron';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_JUPITER = 'symboltables_planets_jupiter';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_NEPTUNE = 'symboltables_planets_neptune';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_SATURN = 'symboltables_planets_saturn';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_URANUS = 'symboltables_planets_uranus';
const ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_PLUTO = 'symboltables_planets_pluto';

const ZODIACSIGNS = {
  'astronomy_signs_aries': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 3,
      'start_day': 21,
      'end_month': 4,
      'end_day': 20,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_MARS],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 1,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_FIRE,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_MASCULINE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_CARDINAL
  },
  'astronomy_signs_taurus': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 4,
      'start_day': 21,
      'end_month': 5,
      'end_day': 20,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_VENUS],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 2,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_EARTH,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_FEMININE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_FIXED
  },
  'astronomy_signs_gemini': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 5,
      'start_day': 21,
      'end_month': 6,
      'end_day': 21,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_MERCURY],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 3,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_AIR,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_MASCULINE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_MUTABLE
  },
  'astronomy_signs_cancer': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 6,
      'start_day': 22,
      'end_month': 7,
      'end_day': 22,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_MOON],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 4,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_WATER,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_FEMININE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_CARDINAL
  },
  'astronomy_signs_leo': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 7,
      'start_day': 23,
      'end_month': 8,
      'end_day': 23,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_SUN],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 5,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_FIRE,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_MASCULINE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_FIXED
  },
  'astronomy_signs_virgo': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 8,
      'start_day': 24,
      'end_month': 9,
      'end_day': 23,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [
      ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_MERCURY,
      ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_CHIRON
    ],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 6,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_EARTH,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_FEMININE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_MUTABLE
  },
  'astronomy_signs_libra': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 9,
      'start_day': 24,
      'end_month': 10,
      'end_day': 23,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_VENUS],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 7,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_AIR,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_MASCULINE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_CARDINAL
  },
  'astronomy_signs_scorpio': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 10,
      'start_day': 24,
      'end_month': 11,
      'end_day': 22,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [
      ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_PLUTO,
      ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_JUPITER
    ],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 8,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_WATER,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_FEMININE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_FIXED
  },
  'astronomy_signs_sagittarius': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 11,
      'start_day': 23,
      'end_month': 12,
      'end_day': 21,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_JUPITER],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 9,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_FIRE,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_MASCULINE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_MUTABLE
  },
  'astronomy_signs_capricorn': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 12,
      'start_day': 22,
      'end_month': 1,
      'end_day': 20,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_SATURN],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 10,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_EARTH,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_FEMININE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_CARDINAL
  },
  'astronomy_signs_aquarius': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 1,
      'start_day': 21,
      'end_month': 2,
      'end_day': 19,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [
      ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_URANUS,
      ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_SATURN
    ],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 11,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_AIR,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_MASCULINE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_FIXED
  },
  'astronomy_signs_pisces': {
    ZODIACSIGNS_ATTRIBUTE_DATE: {
      'start_month': 2,
      'start_day': 20,
      'end_month': 3,
      'end_day': 20,
    },
    ZODIACSIGNS_ATTRIBUTE_PLANET: [
      ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_NEPTUNE,
      ZODIACSIGNS_ATTRIBUTE_PLANET_VALUE_JUPITER
    ],
    ZODIACSIGNS_ATTRIBUTE_HOUSE: 12,
    ZODIACSIGNS_ATTRIBUTE_ELEMENT: ZODIACSIGNS_ATTRIBUTE_ELEMENT_VALUE_WATER,
    ZODIACSIGNS_ATTRIBUTE_POLARITY: ZODIACSIGNS_ATTRIBUTE_POLARITY_VALUE_FEMININE,
    ZODIACSIGNS_ATTRIBUTE_QUALITY: ZODIACSIGNS_ATTRIBUTE_QUALITY_VALUE_MUTABLE
  },
};