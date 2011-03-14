jQuery(function ($) {
  $.fn.extend({
    updateConversationButtonText: function(){
      var el = this;
      
      return el.parents('.contribution-container').each(function(){
        var $this = $(this),
            $convoUtility = $this.find('.convo-utility').first(),
            $responsesButton = $this.find('.conversation-responses').first(),
            $actionButton = $this.find('.conversation-action').first(),
            incrementedText;
        
        if ( $convoUtility.size() > 0 ) {
          $convoUtility.addClass('response').removeClass('no-response');
        }
        
        if ( $actionButton.size() > 0 ) {
          $actionButton.text("Respond");
        }
        
        // there is no parent button if responding to convo-level responses at bottom of convo perma page
        if ( $responsesButton.size() > 0 ) { 
          if ( $responsesButton.data('origText') == null ) { $responsesButton.data('origText', $responsesButton.text()); }
          
          if( /^[^\d]+$/.test($responsesButton.data('origText')) ){ // if origText does not contain a number (most likely says something like "Be the first to respond", but we'll be flexible)
            $responsesButton.data('origText',"0 Response");
          }
          integers = $responsesButton.data('origText').match(/(\d+)/g);
          
          $.each(integers, function(){
            incrementedText = $responsesButton.data('origText').replace(this,parseInt(this)+1);
            // if this == 0, then incremented == 1, so no pluralization
            if(this != 0){ incrementedText = incrementedText.replace(/Response$/, 'Responses'); }
          });
          $responsesButton
            .data('origText', incrementedText);
            
          if( $responsesButton.is('span') ) { $responsesButton.text(incrementedText); }
        }
      });
    },
    
    bindContributionFormEvents: function(clicked,tabStrip){
      var form = this;
      form
        .bind("submit", function(){
          $(this).find('input[placeholder], textarea[placeholder]').each( function() {
            $this = $(this);
            if( $this.val() == $this.attr('placeholder') ){
              $this.val('');
            }
          });
        })
        .maskOnSubmit(tabStrip)
        .bind("ajax:success", function(evt, data, status, xhr){
          // apparently there is no way to inspect the HTTP status returned when submitting via iframe (which happens for AJAX file/image uploads)
          //  so, if file/image uploads via this form will always trigger ajax:success even if action returned error status code.
          //  But for this action, successes always return HTML and failures return JSON of the error messages, so we'll test if response is JSON and trigger failure if so
          try{
            $.parseJSON(data); // throws error if data is not JSON
            return $(this).trigger('ajax:complete').trigger('ajax:failure', xhr, status, data); // only gets to here if JSON parsing was successful, meaning data is error messages
          }catch(err){
            // do nothing
          }
          var preview = this.getAttribute('data-preview'),
              divId = $(tabStrip).attr('id'),
              responseNode;
              
          if( $(this).data('remotipartSubmitted') == 'script' ) {
            responseNode = $($("<div />").html(xhr.responseText).text()); // this is needed to properly unescape the HTML returned from doing the jquery.form plugin's ajaxSubmit for some reason
          } else {
            responseNode = $(xhr.responseText);            
          }
          
          if(preview == "true") {
            var previewTab = '#' + divId + '-preview',
                // populate the preview div with a preview and a filled-in form with data-preview = false so it can be submitted again
                previewPane = $(this).closest('div').siblings('.contribution-preview');
            
            // bind these ajax handlers to preview form, also add reference to this form on the new preview form
            previewPane.html(responseNode).find('form').bindContributionFormEvents(clicked,tabStrip).data('origForm',$(this));
            
            $(this).find('.validation-error').html(''); // clear any previous errors from form
            $(tabStrip).easytabs('select','li.preview-tab').find(".contribution-preview").find("a.cancel").click(function(e){
              $(tabStrip).easytabs('select', $(this).attr("href"));
              e.preventDefault();
            });
          } else {
            var optionsTab = '#' + divId + '-options',
                origForm = $(this).data('origForm');
            
            if ( ! $(clicked).data('colorbox') ) { // unless element has colorbox applied, then clean up the overridden toggle action
              $(clicked).unbind('click'); // only unbinds the click function that attaches the toggle, since all the other events are indirectly attached through .live()
            }
            if ( ! $(clicked).hasClass('top-node-conversation-action') ) {
              $(clicked).updateConversationButtonText();

              var $showResponsesButton = $(clicked).closest('.response').find('.conversation-responses');
              if ( ! $showResponsesButton.data('expanded') ) {
                $showResponsesButton.bind('ajax:success', function(){
                  var $target = $(this).closest('.contribution-container').find('ol.thread-list,ul.thread-list').first(),
                      responseId = responseNode.filter('li').first().attr('id');
              
                  setTimeout(function(){ $target.find('#' + responseId).scrollTo(); }, 250);
                }).trigger('click'); // expands
              }
            }
            
            $(clicked).appendContributionToThread(responseNode);
            $.fn.colorbox.close();
            setTimeout(function(){ responseNode.scrollTo(); }, 250);
          }
        })
        .bindValidationErrorOnAjaxFailure()
        .find('[placeholder]').placeholder({className: 'placeholder'});
        return this
      },
      
      appendContributionToThread: function(responseNode) {
        var $target = this.closest('.contribution-container').find('ol.thread-list,ul.thread-list').first().find('.contribution-thread-div').first(),
            contribution = responseNode.children('li').attr('id'),
            $contributionOnPage = $target.find('li#' + contribution);
        
        if ( this.hasClass('top-node-conversation-action') ) {
          $contributionOnPage = $('ol#conversation-thread-list').append(responseNode);
        } else if ( $contributionOnPage.size > 0 ){
          $contributionOnPage = $contributionOnPage.replaceWith(responseNode);
        } else {
          $contributionOnPage = $target.append(responseNode);
        }
        $contributionOnPage.find('.rate-form-container').hide();
        return $contributionOnPage;
      },
      
      applyEasyTabsToTabStrip: function() {
        var $container = this;
        
        if ( $container.length == 0 ) { return this; }
        
        $container
          .resizeResponseInputs()
          .easytabs({
            tabActiveClass: 'tab-active',
            tabActivePanel: 'panel-active',
            tabs: '> .tab-area > .tab-strip-options > ul > li',
            defaultTab: '.default-tab',
            animationSpeed: 250,
            updateHash: false
          })
          .live("easytabs:after", function(){
            resizeColorbox();
          });
      },
      
      resizeResponseInputs: function() {
        var $container = this,
            $tabs = $container.find('.tab-strip-options'),
            $horizontalAdjust = $container.find('div.panels,label,textarea'),
            $verticalAdjust = $container.find('textarea');
            
        $horizontalAdjust.each(function() {
          var $this = $(this),
              horizontalPadding = parseFloat($this.css('paddingLeft')) + parseFloat($this.css('paddingRight')),
              horizontalBorder = $this.outerWidth() - $this.innerWidth();

          $this.width( $container.innerWidth() - $tabs.outerWidth() - horizontalPadding - horizontalBorder - 2 );
        });
        $verticalAdjust.each(function() {
          var $this = $(this),
            verticalPadding = parseFloat($this.css('paddingTop')) + parseFloat($this.css('paddingBottom')),
            verticalBorder = $this.outerWidth() - $this.innerWidth(),
            $sibling = $(this).siblings('label').first(),
            extraVerticalSpace = 0;
          
          if ( $sibling.size() > 0 ) {
            extraVerticalSpace = $sibling.outerHeight();
          }
            
          $this.height( $tabs.outerHeight() - verticalPadding - verticalBorder - extraVerticalSpace );
        });
        return $container;
      },
      
      bindValidationErrorOnAjaxFailure: function() {
        this.bind("ajax:failure", function(evt, xhr, status, error){
          try{
            var errors = $.parseJSON(xhr.responseText);
          }catch(err){
            var errors = ["Please reload the page and try again"];
          }
          var errorString = "There were errors with the submission:\n<ul>";
          for(error in errors){
            errorString += "<li>" + errors[error] + "</li> ";
          }
          errorString += "</ul>"
          $(this).find(".validation-error").html(errorString);
          setTimeout(function(){
            resizeColorbox(); // need to delay this a little to give the new html a chance to be appended in the DOM
          }, 100);
        });
        return this;
      },
      
      liveAlertOnAjaxFailure: function() {
        this.live("ajax:failure", function(evt, xhr, status, error){
          try{
            var errors = $.parseJSON(xhr.responseText);
          }catch(err){
            var errors = {msg: "Please reload the page and try again"};
          }
          var errorString = "There were errors loading the edit form:\n\n";
          for(error in errors){
            errorString += errors[error] + "\n";
          }
          alert(errorString);
        });
        return this;
      },
      
      maskOnSubmit: function(container) {
        if(container == undefined) { container = this; }
        this
          .bind("ajax:loading", function(){
            $(container).mask("Loading...");
          })
          .bind("ajax:complete", function(){
            $(container).unmask();
          });
        return this;
      },
      
      changeTextOnLoading: function(options) {
        var opts = $.extend({}, {
          loadText: "Loading...",
          completeText: function(){
            $(this).data('origText');
          }
        }, options);

        this
          .live("ajax:loading", function(){
            var $this = $(this);
            if ( $this.data('origText') == null ) { $this.data('origText', $this.text()); }
            $this.text(opts.loadText);
          })
          .live("ajax:complete", function(evt, xhr){
            $(this).text(opts.completeText);
          });
        return this;
      },

      applyToggleToElement: function(target,altText){
        var $clicked = $(this),
            altText = altText || "Hide";
        $clicked.toggle(
        	function(){
        		$clicked.text($clicked.data('origText'));
        		$clicked.data('expanded', false);
        		$(target).slideUp();
        	}, 
        	function(){
        		$clicked.text(altText);
        		$clicked.data('expanded', true);
        		$(target).slideDown();
        	}
        );
      }

  });
  
  $(document).ready(function() {
    selectResponseFromHash = function(){
      var hash = window.location.hash.match(/^#node-([\d]+)/);

      if ( hash && hash[1] ){
        var responseId = hash[1],
            $onPage = $('#show-contribution-' + responseId);

        // Permalink to contribution already on page (e.g. TopLevelContribution)
        if ( $onPage.size() > 0 ) {
          return $onPage.scrollTo();
        } else {
          $('.feature-mast').mask('Loading response...');
          $.ajax({
            url: 'node_permalink/' + responseId,
            dataType: 'js',
            type: 'GET',
            complete: function(){
              $('.feature-mast').unmask();
            },
            success: function (data, status, xhr) {
              eval(xhr.responseText);

              // Give enough time for target node to append to DOM
              setTimeout( function(){ 
                var $target = $('#show-contribution-' + responseId);

                // Change all parent "x Responses" buttons to say "View all x Responses"
                // to make it clear that the thread is only partially expanded to view
                // the permalinked response.
                $target.parents('.contribution-container').each(function(){
                  $(this).find('a.conversation-responses').first().text( function(){
                    var $this = $(this);
                    if ( /[\d]+ responses/i.test($this.text()) ) {
                      // $this.text( $this.text().replace(/([\d]+ responses)/i, "View $1") );
                    } else {
                      $this.data('origText', $this.text()).text("Hide response").applyToggleToElement($target, "Hide Response");
                    }
                  });
                });

                $target.scrollTo();

              }, 250);
            }
          });
        }
      }
    }
    
    resizeColorbox = function(){
      $.colorbox.resize({
        innerHeight: $('#cboxLoadedContent').children().first().outerHeight() + 30
      });
    }
    
    selectResponseFromHash();
    $(window).hashchange( function(){
      selectResponseFromHash();
    });

    $('.delete-conversation-action')
      .changeTextOnLoading({
        loadText: "Deleting..."
      })
      .live("ajax:success", function(evt, data, status, xhr){
        var clicked = this,
            target = this.getAttribute("data-target");
        $(target).hide('puff', 1000);
      })
      .liveAlertOnAjaxFailure();
    
    $('.edit-conversation-action')
      .changeTextOnLoading()
      .live("ajax:success", function(evt, data, status, xhr){
        var clicked = this;
            target = this.getAttribute("data-target");
            form = target + ' form';
        $(target).html(xhr.responseText);
        $(form)
          .maskOnSubmit()
          .bind("ajax:success", function(evt, data, status, xhr){
            if( $(this).data('remotipartSubmitted') == 'script' ) {
              var responseNode = $($("<div />").html(xhr.responseText).text()); // this is needed to properly unescape the HTML returned from doing the jquery.form plugin's ajaxSubmit for some reason
            } else {
              var responseNode = $(xhr.responseText);            
            }
            contributionContent = $(responseNode).html();
            $(target).html(contributionContent).find('.rate-form-container').hide();
          })
          .bindValidationErrorOnAjaxFailure();
      })
      .liveAlertOnAjaxFailure();
    
    $('.top-node-conversation-action,.conversation-action').live('click', function(e){
      var $this = $(this);
      $.colorbox({
        transition: 'fade', // needed to fix colorbox bug with jquery 1.4.4
        href: $this.attr('href'),
        width: '600px',
        height: '340px',
        onComplete: function(){
          var clicked = $this,
              divId = $(clicked).attr('href').match(/div_id=([^&]+)/)[1],
              tabStrip = '.tab-strip#' + divId,
              form = tabStrip + ' form';
          
          $(tabStrip).applyEasyTabsToTabStrip();
          $(form).bindContributionFormEvents(clicked,tabStrip);
        },
        opacity: 0.6
        //scrolling: false
      });
      e.preventDefault();
    });
    
    $('a[data-colorbox-iframe]').live('click', function(e){
      $.colorbox({ 
        transition: 'fade', // needed to fix colorbox bug with jquery 1.4.4
        href: $(this).attr('href'), 
        iframe: true, 
        width: '75%', 
        height: '75%',
        onClosed: function(){
          alert('And this is where we could reload this section of the conversation page!');
        }
       });
      e.preventDefault();
    });
  });
});
