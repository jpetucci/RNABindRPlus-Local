
(function($) {
  Drupal.behaviors.CToolsJumpMenu = {
    attach: function(context) {
      $('.ctools-jump-menu-hide')
        .once('ctools-jump-menu')
        .hide();

      $('.ctools-jump-menu-change')
        .once('ctools-jump-menu')
        .change(function() {
          var loc = $(this).val();
          var urlArray = loc.split('::');
          if (urlArray[1]) {
            location.href = urlArray[1];
          }
          else {
            location.href = loc;
          }
          return false;
        });

      $('.ctools-jump-menu-button')
        .once('ctools-jump-menu')
        .click(function() {
          // Instead of submitting the form, just perform the redirect.

          // Find our sibling value.
          var $select = $(this).parents('form').find('.ctools-jump-menu-select');
          var loc = $select.val();
          var urlArray = loc.split('::');
          if (urlArray[1]) {
            location.href = urlArray[1];
          }
          else {
            location.href = loc;
          }
          return false;
        });
    }
  }
})(jQuery);
;
var version = getInternetExplorerVersion();
if (version === -1 || version > 9) {
  var addClass = window.setInterval(addResponsiveClass, 5);
}

function addResponsiveClass() {
  if (document.body !== null) {
    width = document.body.clientWidth;
    if (width < 740) {
      document.body.className += " responsive-layout-mobile";
    }
    else if (width < 980) {
      document.body.className += " responsive-layout-narrow";
    }
    else {
      document.body.className += " responsive-layout-normal";
    }
    
    window.clearInterval(addClass);
  }
}


function getInternetExplorerVersion(){
  var version = -1; // Return value assumes failure.
  if (navigator.appName == 'Microsoft Internet Explorer'){
    var ua = navigator.userAgent;
    var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
    if (re.exec(ua) != null){
      version = parseFloat( RegExp.$1 );
    }
  }
  return version;
};
