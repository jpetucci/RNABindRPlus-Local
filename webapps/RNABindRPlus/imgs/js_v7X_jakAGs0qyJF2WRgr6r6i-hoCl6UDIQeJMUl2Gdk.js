/*	
 *	jQuery dotdotdot 1.5.6
 *	
 *	Copyright (c) 2013 Fred Heusschen
 *	www.frebsite.nl
 *
 *	Plugin website:
 *	dotdotdot.frebsite.nl
 *
 *	Dual licensed under the MIT and GPL licenses.
 *	http://en.wikipedia.org/wiki/MIT_License
 *	http://en.wikipedia.org/wiki/GNU_General_Public_License
 */


(function( $ )
{
	if ( $.fn.dotdotdot )
	{
		return;
	}

	$.fn.dotdotdot = function( o )
	{
		if ( this.length == 0 )
		{
			debug( true, 'No element found for "' + this.selector + '".' );
			return this;
		}
		if ( this.length > 1 )
		{
			return this.each(
				function()
				{
					$(this).dotdotdot( o );
				}
			);
		}


		var $dot = this;

		if ( $dot.data( 'dotdotdot' ) )
		{
			$dot.trigger( 'destroy.dot' );
		}

		$dot.bind_events = function()
		{
			$dot.bind(
				'update.dot',
				function( e, c )
				{
					e.preventDefault();
					e.stopPropagation();

					opts.maxHeight = ( typeof opts.height == 'number' ) 
						? opts.height 
						: getTrueInnerHeight( $dot );

					opts.maxHeight += opts.tolerance;

					if ( typeof c != 'undefined' )
					{
						if ( typeof c == 'string' || c instanceof HTMLElement )
						{
					 		c = $('<div />').append( c ).contents();
						}
						if ( c instanceof $ )
						{
							orgContent = c;
						}
					}

					$inr = $dot.wrapInner( '<div class="dotdotdot" />' ).children();
					$inr.empty()
						.append( orgContent.clone( true ) )
						.css({
							'height'	: 'auto',
							'width'		: 'auto',
							'border'	: 'none',
							'padding'	: 0,
							'margin'	: 0
						});

					var after = false,
						trunc = false;

					if ( conf.afterElement )
					{
						after = conf.afterElement.clone( true );
						conf.afterElement.remove();
					}
					if ( test( $inr, opts ) )
					{
						if ( opts.wrap == 'children' )
						{
							trunc = children( $inr, opts, after );
						}
						else
						{
							trunc = ellipsis( $inr, $dot, $inr, opts, after );
						}
					}
					$inr.replaceWith( $inr.contents() );
					$inr = null;
					
					if ( $.isFunction( opts.callback ) )
					{
						opts.callback.call( $dot[ 0 ], trunc, orgContent );
					}

					conf.isTruncated = trunc;
					return trunc;
				}

			).bind(
				'isTruncated.dot',
				function( e, fn )
				{
					e.preventDefault();
					e.stopPropagation();

					if ( typeof fn == 'function' )
					{
						fn.call( $dot[ 0 ], conf.isTruncated );
					}
					return conf.isTruncated;
				}

			).bind(
				'originalContent.dot',
				function( e, fn )
				{
					e.preventDefault();
					e.stopPropagation();

					if ( typeof fn == 'function' )
					{
						fn.call( $dot[ 0 ], orgContent );
					}
					return orgContent;
				}

			).bind(
				'destroy.dot',
				function( e )
				{
					e.preventDefault();
					e.stopPropagation();

					$dot.unwatch()
						.unbind_events()
						.empty()
						.append( orgContent )
						.data( 'dotdotdot', false );
				}
			);
			return $dot;
		};	//	/bind_events

		$dot.unbind_events = function()
		{
			$dot.unbind('.dot');
			return $dot;
		};	//	/unbind_events

		$dot.watch = function()
		{
			$dot.unwatch();
			if ( opts.watch == 'window' )
			{
				var $window = $(window),
					_wWidth = $window.width(),
					_wHeight = $window.height(); 

				$window.bind(
					'resize.dot' + conf.dotId,
					function()
					{
						if ( _wWidth != $window.width() || _wHeight != $window.height() || !opts.windowResizeFix )
						{
							_wWidth = $window.width();
							_wHeight = $window.height();
	
							if ( watchInt )
							{
								clearInterval( watchInt );
							}
							watchInt = setTimeout(
								function()
								{
									$dot.trigger( 'update.dot' );
								}, 10
							);
						}
					}
				);
			}
			else
			{
				watchOrg = getSizes( $dot );
				watchInt = setInterval(
					function()
					{
						var watchNew = getSizes( $dot );
						if ( watchOrg.width  != watchNew.width ||
							 watchOrg.height != watchNew.height )
						{
							$dot.trigger( 'update.dot' );
							watchOrg = getSizes( $dot );
						}
					}, 100
				);
			}
			return $dot;
		};
		$dot.unwatch = function()
		{
			$(window).unbind( 'resize.dot' + conf.dotId );
			if ( watchInt )
			{
				clearInterval( watchInt );
			}
			return $dot;
		};

		var	orgContent	= $dot.contents(),
			opts 		= $.extend( true, {}, $.fn.dotdotdot.defaults, o ),
			conf		= {},
			watchOrg	= {},
			watchInt	= null,
			$inr		= null;

		conf.afterElement	= getElement( opts.after, $dot );
		conf.isTruncated	= false;
		conf.dotId			= dotId++;


		$dot.data( 'dotdotdot', true )
			.bind_events()
			.trigger( 'update.dot' );

		if ( opts.watch )
		{
			$dot.watch();
		}

		return $dot;
	};


	//	public
	$.fn.dotdotdot.defaults = {
		'ellipsis'	: '... ',
		'wrap'		: 'word',
		'lastCharacter': {
			'remove'		: [ ' ', ',', ';', '.', '!', '?' ],
			'noEllipsis'	: []
		},
		'tolerance'	: 0,
		'callback'	: null,
		'after'		: null,
		'height'	: null,
		'watch'		: false,
		'windowResizeFix': true,
		'debug'		: false
	};
	

	//	private
	var dotId = 1;

	function children( $elem, o, after )
	{
		var $elements 	= $elem.children(),
			isTruncated	= false;

		$elem.empty();

		for ( var a = 0, l = $elements.length; a < l; a++ )
		{
			var $e = $elements.eq( a );
			$elem.append( $e );
			if ( after )
			{
				$elem.append( after );
			}
			if ( test( $elem, o ) )
			{
				$e.remove();
				isTruncated = true;
				break;
			}
			else
			{
				if ( after )
				{
					after.remove();
				}
			}
		}
		return isTruncated;
	}
	function ellipsis( $elem, $d, $i, o, after )
	{
		var $elements 	= $elem.contents(),
			isTruncated	= false;

		$elem.empty();

		var notx = 'table, thead, tbody, tfoot, tr, col, colgroup, object, embed, param, ol, ul, dl, select, optgroup, option, textarea, script, style';
		for ( var a = 0, l = $elements.length; a < l; a++ )
		{

			if ( isTruncated )
			{
				break;
			}

			var e	= $elements[ a ],
				$e	= $(e);

			if ( typeof e == 'undefined' )
			{
				continue;
			}

			$elem.append( $e );
			if ( after )
			{
				$elem[ ( $elem.is( notx ) ) ? 'after' : 'append' ]( after );
			}
			if ( e.nodeType == 3 )
			{
				if ( test( $i, o ) )
				{
					isTruncated = ellipsisElement( $e, $d, $i, o, after );
				}
			}
			else
			{
				isTruncated = ellipsis( $e, $d, $i, o, after );
			}

			if ( !isTruncated )
			{
				if ( after )
				{
					after.remove();
				}
			}
		}
		return isTruncated;
	}
	function ellipsisElement( $e, $d, $i, o, after )
	{
		var isTruncated	= false,
			e = $e[ 0 ];

		if ( typeof e == 'undefined' )
		{
			return false;
		}

		var seporator	= ( o.wrap == 'letter' ) ? '' : ' ',
			textArr		= getTextContent( e ).split( seporator ),
			position 	= -1,
			midPos		= -1,
			startPos	= 0,
			endPos		= textArr.length - 1;

		while ( startPos <= endPos )
		{
			var m = Math.floor( ( startPos + endPos ) / 2 );
			if ( m == midPos ) 
			{
				break;
			}
			midPos = m;

			setTextContent( e, textArr.slice( 0, midPos + 1 ).join( seporator ) + o.ellipsis );

			if ( !test( $i, o ) )
			{
				position = midPos;
				startPos = midPos; 
			}
			else
			{
				endPos = midPos;
			}				
		}	
	
		if ( position != -1 && !( textArr.length == 1 && textArr[ 0 ].length == 0 ) )
		{
			var txt = addEllipsis( textArr.slice( 0, position + 1 ).join( seporator ), o );
			isTruncated = true;
			setTextContent( e, txt );
		}
		else
		{
			var $w = $e.parent();
			$e.remove();

			var afterLength = ( after ) ? after.length : 0 ;

			if ( $w.contents().size() > afterLength )
			{
				var $n = $w.contents().eq( -1 - afterLength );
				isTruncated = ellipsisElement( $n, $d, $i, o, after );
			}
			else
			{
				var e = $w.prev().contents().eq( -1 )[ 0 ];

				if ( typeof e != 'undefined' )
				{
					var txt = addEllipsis( getTextContent( e ), o );
					setTextContent( e, txt );
					$w.remove();
					isTruncated = true;
				}

			}
		}

		return isTruncated;
	}
	function test( $i, o )
	{
		return $i.innerHeight() > o.maxHeight;
	}
	function addEllipsis( txt, o )
	{
		while( $.inArray( txt.slice( -1 ), o.lastCharacter.remove ) > -1 )
		{
			txt = txt.slice( 0, -1 );
		}
		if ( $.inArray( txt.slice( -1 ), o.lastCharacter.noEllipsis ) < 0 )
		{
			txt += o.ellipsis;
		}
		return txt;
	}
	function getSizes( $d )
	{
		return {
			'width'	: $d.innerWidth(),
			'height': $d.innerHeight()
		};
	}
	function setTextContent( e, content )
	{
		if ( e.innerText )
		{
			e.innerText = content;
		}
		else if ( e.nodeValue )
		{
			e.nodeValue = content;
		}
		else if (e.textContent)
		{
			e.textContent = content;
		}

	}
	function getTextContent( e )
	{
		if ( e.innerText )
		{
			return e.innerText;
		}
		else if ( e.nodeValue )
		{
			return e.nodeValue;
		}
		else if ( e.textContent )
		{
			return e.textContent;
		}
		else
		{
			return "";
		}
	}
	function getElement( e, $i )
	{
		if ( typeof e == 'undefined' )
		{
			return false;
		}
		if ( !e )
		{
			return false;
		}
		if ( typeof e == 'string' )
		{
			e = $(e, $i);
			return ( e.length )
				? e 
				: false;
		}
		if ( typeof e == 'object' )
		{
			return ( typeof e.jquery == 'undefined' )
				? false
				: e;
		}
		return false;
	}
	function getTrueInnerHeight( $el )
	{
		var h = $el.innerHeight(),
			a = [ 'paddingTop', 'paddingBottom' ];

		for ( var z = 0, l = a.length; z < l; z++ ) {
			var m = parseInt( $el.css( a[ z ] ), 10 );
			if ( isNaN( m ) )
			{
				m = 0;
			}
			h -= m;
		}
		return h;
	}
	function debug( d, m )
	{
		if ( !d )
		{
			return false;
		}
		if ( typeof m == 'string' )
		{
			m = 'dotdotdot: ' + m;
		}
		else
		{
			m = [ 'dotdotdot:', m ];
		}

		if ( typeof window.console != 'undefined' )
		{
			if ( typeof window.console.log != 'undefined' )
			{
				window.console.log( m );
			}
		}
		return false;
	}
	

	//	override jQuery.html
	var _orgHtml = $.fn.html;
    $.fn.html = function( str ) {
		if ( typeof str != 'undefined' )
		{
			if ( this.data( 'dotdotdot' ) )
			{
				if ( typeof str != 'function' )
				{
					return this.trigger( 'update', [ str ] );
				}
			}
			return _orgHtml.call( this, str );
		}
		return _orgHtml.call( this );
    };


	//	override jQuery.text
	var _orgText = $.fn.text;
    $.fn.text = function( str ) {
		if ( typeof str != 'undefined' )
		{
			if ( this.data( 'dotdotdot' ) )
			{
				var temp = $( '<div />' );
				temp.text( str );
				str = temp.html();
				temp.remove();
				return this.trigger( 'update', [ str ] );
			}
			return _orgText.call( this, str );
		}
        return _orgText.call( this );
    };


})( jQuery );
;
(function(a){a.fn.extend({customSelect:function(b){if(typeof document.body.style.maxHeight!="undefined"){var c={customClass:null,mapClass:true,mapStyle:true};var b=a.extend(c,b);return this.each(function(){var d=a(this);var f=a('<span class="customSelectInner" />');var e=a('<span class="customSelect" />').append(f);d.after(e);if(b.customClass){e.addClass(b.customClass)}if(b.mapClass){e.addClass(d.attr("class"))}if(b.mapStyle){e.attr("style",d.attr("style"))}d.bind("update",function(){d.change();var h=parseInt(d.outerWidth())-(parseInt(e.outerWidth())-parseInt(e.width()));e.css({display:"inline-block"});f.css({width:h,display:"inline-block"});var g=e.outerHeight();d.css({"-webkit-appearance":"menulist-button",width:e.outerWidth(),position:"absolute",opacity:0,height:g,fontSize:e.css("font-size")})}).change(function(){var g=d.find(":selected");var h=g.html()||"&nbsp;";f.html(h).parent().addClass("customSelectChanged");setTimeout(function(){e.removeClass("customSelectOpen")},60)}).bind("mousedown",function(){e.toggleClass("customSelectOpen")}).focus(function(){e.addClass("customSelectFocus")}).blur(function(){e.removeClass("customSelectFocus customSelectOpen")}).trigger("update")})}}})})(jQuery);;
// Using the closure to map jQuery to $.
(function ($) {

// Store our function as a property of Drupal.behaviors.

// Equal Column Heights
Drupal.behaviors.equalHeights = {
  attach: function (context, settings) {
	  $('.node-type-feature-article #zone-content').addClass('equal-height-container');
	  $('.node-type-feature-article #region-content').addClass('equal-height-element');	
	  $('.node-type-feature-article #region-sidebar-second').addClass('equal-height-element');	  
	  $('.view-mode-full #zone-content').addClass('equal-height-container');
	  $('.view-mode-full #region-content').addClass('equal-height-element');	
	  $('.view-mode-full #region-sidebar-second').addClass('equal-height-element');	 
  }
};

// Set Last class on sub-footer links
Drupal.behaviors.subFooterLastClass = {
  attach: function (context, settings) {
    $(".footer-left .links ul li:first-child").addClass("first");
    $(".footer-right .links ul li:first-child").addClass("first");
    $(".footer-left .links ul li:last-child").addClass("last");
    $(".footer-right .links ul li:last-child").addClass("last");
  }
};

// Hover states for certain blue bar links
Drupal.behaviors.blueBarHovers = {
  attach: function (context, settings) {
    $("#block-psu-homepage-psu-content-header-bar .bar-link a, .group_quadrant_four .bar-link a").hover(
      function () {
        $(this).parent().addClass('bar-link-hover');
      },
      function () {
        $(this).parent().removeClass('bar-link-hover');
      }
    );
    $(".bar-link .form-select").hover(
      function () {
        $(this).parents('.bar-link').addClass('bar-link-hover');
        $(this).addClass('bar-link-hover');
        $(this).siblings('.form-select').addClass('bar-link-hover');
      },
      function () {
        $(this).parents('.bar-link').removeClass('bar-link-hover');
        $(this).removeClass('bar-link-hover');
        $(this).siblings('.form-select').removeClass('bar-link-hover');
      }
    );    
  }
};

// Footer Image Map hover
Drupal.behaviors.footerMapHover = {
  attach: function (context, settings) {
    $("#block-boxes-penn-state-image-map #penn-map a").hover(
      function () {
        $(this).children('img').attr('src', '/profiles/psu_profile/themes/psu_main/images/bg-penn-map-hover.png');
      },
      function () {
        $(this).children('img').attr('src', '/profiles/psu_profile/themes/psu_main/images/bg-penn-map.png');
      }
    );
  }
};

// Title/Alt text changes for Gallery/Video areas on homepage
Drupal.behaviors.homeTitleAlt = {
  attach: function (context, settings) {
    $('.group_quadrant_two .field-name-field-gallery .field-name-field-thumbnail-image a img, .group_quadrant_two .field-name-field-gallery .field-name-field-images a img, .group_quadrant_three .field-name-field-video-lower-left .field-name-field-thumbnail-image a img, .group_quadrant_three .field-name-field-video-lower-left .field-name-field-video a img').each(function () {
      $(this).parent().attr('title', $(this).attr('title')),
      $(this).parent().attr('alt', $(this).attr('alt'));
    });
  }
};

// Customized select box for topic bar dropdown
Drupal.behaviors.topicsDropdown = {
  attach: function (context, settings) {
	  $('.view-topics-dropdown .form-type-select select').customSelect();	   
  }
};

// Add last class to audience nav for theming
Drupal.behaviors.audienceNav = {
  attach: function (context, settings) {
    $(".block-menu-audience-menu li:nth-child(3n)").addClass("third");	
    $(".block-menu-audience-menu li:nth-child(2n)").addClass("mobile-last");
  }
};

// Add last class to feature article page right rail
Drupal.behaviors.featureRightRail = {
  attach: function (context, settings) {
    $(".node-type-feature-article .region-sidebar-second section:last-child").addClass("last");	
  }
};

// Add clearfix to various blocks
Drupal.behaviors.clearFix = {
  attach: function (context, settings) {
	$('.block-system-main-menu .content > ul.menu').addClass("clearfix");			
  }
};

// Add gold class to audience nav for theming
Drupal.behaviors.utilityNav = {
  attach: function (context, settings) {
    $(".block-menu-utility-menu li:nth-child(4)").addClass("gold");
    $(".block-menu-utility-menu li:nth-child(5)").addClass("gold");
	
    $(".block-menu-utility-menu li:nth-child(4)").addClass("apply");
    $(".block-menu-utility-menu li:nth-child(5)").addClass("give");
  }
};

// Call dotdotdot script for homepage content stream teaser
Drupal.behaviors.textTruncator = {
  attach: function (context, settings) {
    processDotDotDot();
    // Run again after everything loads.
    // We need web fonts loaded to properly calculate size. 
    $(window).bind('load', function() {
      processDotDotDot();
    });
  }
};

function processDotDotDot() {
  // dotdotdot and ie < 7 don't play well.
  if (!$.browser.msie || $.browser.version > 7.0) {
    if ($('.node-type-homepage').length !== 0) {
      // Dotdotdot doesn't handle the upper right homepage field very well.
      var topRightHeight = getHomepageBodyHeight('.field-name-field-news-top-right');
      var leftHeight = getHomepageBodyHeight('.field-name-field-news-top-left');
      var middleRightHeight = getHomepageBodyHeight('.field-name-field-news-middle-right');
      
      $('.field-name-field-news-top-left .field-name-body').dotdotdot({watch: true, height: leftHeight});
      $('.field-name-field-news-top-right .field-name-body').dotdotdot({watch: true, height: topRightHeight});
      $('.field-name-field-news-middle-right .field-name-body').dotdotdot({watch: true, height: middleRightHeight});
    } 
    $('.callout').dotdotdot({watch: true}); 
    //$('#block-views-feature-article-blocks-block-1 #page-title').dotdotdot({watch: true});  /*may put this back in for the ... */
    $('.field-name-field-social-status .field-item').dotdotdot({watch: true});
    $('.related-news-footer .views-row').dotdotdot({watch: true});
  }
}

function getHomepageBodyHeight(selector) {
  var height = $(selector).height();
  height -= $(selector + ' .field-name-field-primary-topic').outerHeight(true);
  height -= $(selector + ' .node-title').outerHeight(true);
  return height;
}

// Add middle class for social media homepage block
Drupal.behaviors.homepageSocial = {
  attach: function (context, settings) {
    $(".field-name-field-social-status .field-item:nth-child(2)").addClass("middle");
  }
};

// Add last class to audience landing page template
// Add fourth class for focus area items
Drupal.behaviors.audienceLanding= {
  attach: function (context, settings) {
    $(".field-name-field-focus-area .field-items .field-item:last-child").addClass("last");
    $(".view-mode-college-and-campus .field-name-field-focus-area .field-items .field-item:nth-child(4n)").addClass("fourth");
    $(".view-mode-admissions-academics .field-name-field-focus-area .field-items .field-item:nth-child(3n)").addClass("third");
  }
};

// Add clearfix to various blocks
Drupal.behaviors.clearFix = {
  attach: function (context, settings) {
    $(".block-college-campus-jump-block .jump-container").addClass("clearfix");		
	$(".block-menu-super-footer-main .content > ul").addClass("clearfix");	
	$("block-landing-page-blocks-block-2 .item-list").addClass("clearfix");		
	$("block-landing-page-blocks-block-2 .item-list ul").addClass("clearfix");	
	$(".block-menu-audience-menu .menu").addClass("clearfix");			
	$("#zone-footer .block-menu ul.menu").addClass("clearfix");			
	$("#map_wrapper").addClass("clearfix");	
	
  }
};



Drupal.behaviors.superFooter = {
  attach: function (context, settings) {
	$(".block-menu-super-footer-main .content > ul").addClass("super-container");
	$(".block-menu-super-footer-main .content .super-container > li").addClass("super-menus");
	$(".super-container .super-menus #connect-with-us").parent().addClass("super-social");	
    $(".super-social li:nth-child(5)").addClass("mobile-last");
    $(".super-social li:nth-child(6)").addClass("mobile");
    $(".super-social li:nth-child(7)").addClass("mobile");
    $(".super-social li:nth-child(8)").addClass("mobile");
  }
};

// Resets dropdown menus on page load with default option
Drupal.behaviors.footerSelect = {
  attach: function (context, settings) {
	$(document).ready(function() { 
		$('.region-footer-first-inner .container-inline .form-item select').attr('selectedIndex', '0'); 
	    $('.view-college-and-campus-jump-menu .container-inline .form-item select').customSelect();
	});
  }
};

// Change label of menus in header
Drupal.behaviors.mainMenuLabel = {
  attach: function (context, settings) {
  	$(".block-system-main-menu h2").html("Menu");
  	$(".block-menu-menu-news-main-menu h2").html("Menu");
  	$(".block-menu-menu-audience-menu h2").html("Information for:");
  }
};

// Create responsive menu for main nav
Drupal.behaviors.psuMainMenu = {
  attach: function (context, settings) {
    $(window).bind('load resize', function(){
      var breakpoint = 740;
      var width = getPageWidth();
      
      //Make the block title a link at mobile, for screen readers
      var header = $('.block-system-main-menu h2');
      if (width < breakpoint) {
        if (header.parent().get(0).tagName !== 'A') {
          header.wrap('<a class="expand-menu" href="javascript:void(0)"/>');
          $('.block-system-main-menu .expand-menu').click(function(){
            $('.block-system-main-menu .content > ul.menu').toggleClass('active');
            $('.block-system-main-menu .expand-menu').toggleClass('active');
          });
        }
      }
      else {
        if (header.parent().get(0).tagName === 'A') {
          header.unwrap();
        }
      }
    });
  }
};

// Create responsive menu for audience nav
Drupal.behaviors.psuAud = {
    attach: function (context, settings) {
      $(window).bind('load resize', function(){
        var breakpoint = 980;
        var width = getPageWidth();
        
        //check if the menu is created or not and fire appropriate calls
        if (typeof menuInitAud == 'undefined' || menuInitAud == false) {
          if(width < breakpoint) {
            menuInitAud = true;
            Drupal.behaviors.psuAud.createMenuAud();
          }
        } else {
          if (width >= breakpoint) {
            menuInitAud = false;
            Drupal.behaviors.psuAud.destroyMenuAud();
          }
        }
      })
    },
    createMenuAud: function (context, settings) {
      $('.block-menu-audience-menu h2.block-title', context).click(function(){
        $('.block-menu-audience-menu', context).toggleClass('active');
      })
    },
    destroyMenuAud: function (context, settings) {
      $('.block-menu-audience-menu h2.block-title', context).unbind('click');
    }
};

// Fix toolbar at different breakpoints
Drupal.behaviors.responsiveToolbar = {
  attach: function (context, settings) {
    var toolbar = $('#toolbar');
    if (toolbar.length !== 0) {
      $(window).resize(function (){
        $('.html').css('padding-top', toolbar.height() + 'px');
      });
    }
  }
}

/**
 * Browser-agnostic function for getting the page width.
 */
function getPageWidth() {
  //different browsers calculate page width differently
  if (navigator.userAgent.indexOf("WebKit") != -1) {
    var width = $(window).width();
  } else {
    //webkit
    var width = window.innerWidth;
  }
  
  return width;
}

}(jQuery));;
