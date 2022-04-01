/**
 * @file
 * Alters the accordion menu functionality.
 */

(function($){
  Drupal.behaviors.subsectionAccordionMenu = {
    attach: function(context, settings){
      //Prevent expansion/collapse on link click.
      $('.accordion-menu-wrapper .accordion-link').each(function() {
        $(this).mousedown(function() {
          return false;
        });
      });
    }
  }
})(jQuery);;
