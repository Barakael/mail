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

    $mdThemingProvider.definePalette('supertech-blue', {
      '50': '#E8EEF4', '100': '#C5D2E0', '200': '#9FB4C9', '300': '#7996B2',
      '400': '#5C7FA1', '500': '#002E5D', '600': '#002850', '700': '#002040',
      '800': '#001830', '900': '#001020', 'A100': '#82B1FF', 'A200': '#448AFF',
      'A400': '#2979FF', 'A700': '#2962FF',
      'contrastDefaultColor': 'light'
    });

    $mdThemingProvider.definePalette('supertech-red', {
      '50': '#F5E8E8', '100': '#E5C5C6', '200': '#D39E9F', '300': '#C17778',
      '400': '#B35A5C', '500': '#7B1113', '600': '#6B0F10', '700': '#570C0D',
      '800': '#430A0A', '900': '#300707', 'A100': '#FF8A80', 'A200': '#FF5252',
      'A400': '#FF1744', 'A700': '#D50000',
      'contrastDefaultColor': 'light'
    });

    $mdThemingProvider.definePalette('frost-grey', greyMap);

    $mdThemingProvider.theme('default')
      .primaryPalette('supertech-blue', {
        'default': '500',
        'hue-1': '400',
        'hue-2': '700',
        'hue-3': '900'
      })
      .accentPalette('supertech-red', {
        'default': '500',
        'hue-1': '300',
        'hue-2': '400',
        'hue-3': '700'
      })
      .backgroundPalette('frost-grey');

    $mdThemingProvider.generateThemesOnDemand(false);
  }
})();
