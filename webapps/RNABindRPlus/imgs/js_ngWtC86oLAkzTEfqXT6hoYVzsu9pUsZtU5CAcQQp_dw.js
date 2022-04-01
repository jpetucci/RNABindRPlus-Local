/**
 * @file 
 * JS to hide search options and show on focus 
 */
;(function ($, D) {
  D.behaviors.psu_search = {
    attach: function(context, settings) {
      var form = $('#block-search-form .form');
      var expandButton = $('#block-search-form .expand-form');
      var textBox = $('#edit-search-block-form--2');
      var toolbar = $('#toolbar');
      if (toolbar.length !== 0) {
        form.css('top', toolbar.height());
      }
    
      /* Search Type Form */
      textBox.focus(function(e) {
        $('.block-search .search-type').show();
      });
      $(window).click(function(e) {
        if ($(window).width() > 740) {
          $('.block-search .search-type').hide();
        }
      });
      $('#block-search-form').click(function(e) {
        e.stopPropagation();
      });
    
      /* Mobile form & button */
      $('html').click(function() {
        if ($(window).width() < 740) {
          contractForm();
        }
      });
      expandButton.click(function(e){
        if ($(window).width() < 740) {
          if (form.is(':visible')) {
            contractForm();
          }
          else {
            expandForm();
          }
        }
      });
      
      var oldSize = $(window).width();
      //Show / hide form between breakpoints
      $(window).resize(function(){
        var newSize = $(window).width();
        if (newSize > 740) {
          form.show();
          $('#page').css('margin-top', 0);
        }
        // Only hide on downsize, not on any resize at mobile
        else if (oldSize > 740) {
          form.hide();
          $('#page').css('margin-top', 0);
        }
        oldSize = $(window).width();
      });
      
      
      function expandForm() {
        form.show();
        $('#page').css('margin-top', form.height() + 'px');
        textBox.focus();
      }
      function contractForm() {
        form.hide();
        $('#page').css('margin-top', 0);
        textBox.blur();
      }
    }
  }
})(jQuery, Drupal); 
;
(function ($) {

// Allow for the workbench info to hide in the toolbar unless expanded.
Drupal.behaviors.workbenchInformation = {
  attach: function (context, settings) {
    var workbenchContainer = $('#toolbar .workbench-information');
    workbenchContainer.find('a.expand-workbench-information').click(function() {
      $(this).toggleClass('active');
      workbenchContainer.find('.workbench-info-block').slideToggle(300);
      
      return false;
    });
  }
};

}(jQuery));
;
/**
 * @file
 * Set the adaptive image cookie based on the window size
 *
 */

// For older browsers that don't support filter()
if (!Array.prototype.filter)
{
  Array.prototype.filter = function(fun /*, thisp */)
  {
    "use strict";

    if (this == null)
      throw new TypeError();

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof fun != "function")
      throw new TypeError();

    var res = [];
    var thisp = arguments[1];
    for (var i = 0; i < len; i++)
    {
      if (i in t)
      {
        var val = t[i]; // in case fun mutates this
        if (fun.call(thisp, val, i, t))
          res.push(val);
      }
    }

    return res;
  };
}


/**
 * Set the cookie with the width value
 */
(function ($) {
  Drupal.behaviors.ais = function () {
    /*
      First, get the actual browser size.
      window.outerWidth/outerHeight answers honestly on Android devices, dishonestly on iOS, and not at all in IE
      window.screen.availWidth/availHeight answers honestly on iOS devices, dishonestly on Android, and not at all in pre-html5 browsers
      $(window).width()/height() will always answer (thanks jQuery!) and is the fall back
    */
    var width = [ window.outerWidth, window.screen.availWidth, $(window).width()];
    var height = [ window.outerHeight, window.screen.availHeight, $(window).height()];
    
    width = width.filter(Number);
    height = height.filter(Number);

    var width = Math.min.apply( Math, width);
    var height = Math.min.apply( Math, height);

    /* Select a method for determining the size */
    var size = width;
    if (Drupal.settings.ais_method == 'both-max') {
      size = Math.max( width, height );
    } else if (Drupal.settings.ais_method == 'both-min') {
      size = Math.min( width, height );
    } else if (Drupal.settings.ais_method == 'width') {
      size = width;
    } else if (Drupal.settings.ais_method == 'height') {
      size = height;
    }

    /* Match an image style and set the cookie */
    var style = Drupal.settings.ais[0];
    for (i in Drupal.settings.ais) {
       if (Number(Drupal.settings.ais[i].size) < size && Number(Drupal.settings.ais[i].size) > Number(style.size)) {
         style = Drupal.settings.ais[i];
       }
    }
    if (style) {
      document.cookie='ais='+style.name+'; path=/';
    } else {
      document.cookie='ais=;path=/;expires=Thu, 01-Jan-1970 00:00:01 GMT';
    }
  }
  $(window).resize(Drupal.behaviors.ais);
}(jQuery));

  // Call the cookie set function right away
  Drupal.behaviors.ais();

;
