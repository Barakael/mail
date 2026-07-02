(function() {
  'use strict';
  angular.module('SOGo.Common')
    .config(configure);

  configure.$inject = ['$mdThemingProvider'];
  function configure($mdThemingProvider) {
    var greyMap = $mdThemingProvider.extendPalette('grey', {
      '200': 'F5F5F5',
      '300': 'E5E5E5',
      '1000': '4C566A'
    });

    $mdThemingProvider.definePalette('ticketfasta-blue', {
      '50': '#E8F0FA', '100': '#C5D9F0', '200': '#9FC0E6', '300': '#79A7DC',
      '400': '#5C94D4', '500': '#0F4D8D', '600': '#0D4379', '700': '#0A3662',
      '800': '#082A4B', '900': '#051D33', 'A100': '#82B1FF', 'A200': '#448AFF',
      'A400': '#2979FF', 'A700': '#2962FF',
      'contrastDefaultColor': 'light'
    });

    $mdThemingProvider.definePalette('ticketfasta-red', {
      '50': '#FDE8EB', '100': '#FAC5CD', '200': '#F79EAB', '300': '#F47789',
      '400': '#F15A6F', '500': '#DC143C', '600': '#C01235', '700': '#A00F2D',
      '800': '#800C24', '900': '#60091B', 'A100': '#FF8A80', 'A200': '#FF5252',
      'A400': '#FF1744', 'A700': '#D50000',
      'contrastDefaultColor': 'light'
    });

    $mdThemingProvider.definePalette('frost-grey', greyMap);

    $mdThemingProvider.theme('default')
      .primaryPalette('ticketfasta-blue', {
        'default': '500',
        'hue-1': '400',
        'hue-2': '700',
        'hue-3': '900'
      })
      .accentPalette('ticketfasta-red', {
        'default': '500',
        'hue-1': '300',
        'hue-2': '400',
        'hue-3': '700'
      })
      .backgroundPalette('frost-grey');

    $mdThemingProvider.generateThemesOnDemand(false);
  }
})();
