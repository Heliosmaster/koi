(function(e){e.fn.bootstrapFileInput=function(){this.each(function(t,n){var r=e(n);if(typeof r.attr("data-bfi-disabled")!="undefined"){return}var i="Browse";if(typeof r.attr("title")!="undefined"){i=r.attr("title")}var s="";if(!!r.attr("class")){s=" "+r.attr("class")}r.wrap('<a class="file-input-wrapper btn btn-default '+s+'"></a>').parent().prepend(e("<span></span>").html(i))}).promise().done(function(){e(".file-input-wrapper").mousemove(function(t){var n,r,i,s,o,u,a,f;r=e(this);n=r.find("input");i=r.offset().left;s=r.offset().top;o=n.width();u=n.height();a=t.pageX;f=t.pageY;moveInputX=a-i-o+20;moveInputY=f-s-u/2;n.css({left:moveInputX,top:moveInputY})});e("body").on("change",".file-input-wrapper input[type=file]",function(){var t;t=e(this).val();e(this).parent().next(".file-input-name").remove();if(!!e(this).prop("files")&&e(this).prop("files").length>1){t=e(this)[0].files.length+" files"}else{t=t.substring(t.lastIndexOf("\\")+1,t.length)}if(!t){return}var n=e(this).data("filename-placement");if(n==="inside"){e(this).siblings("span").html(t);e(this).attr("title",t)}else{e(this).parent().after('<span class="file-input-name">'+t+"</span>")}})})};var t="<style>"+".file-input-wrapper { overflow: hidden; position: relative; cursor: pointer; z-index: 1; }"+".file-input-wrapper input[type=file], .file-input-wrapper input[type=file]:focus, .file-input-wrapper input[type=file]:hover { position: absolute; top: 0; left: 0; cursor: pointer; opacity: 0; filter: alpha(opacity=0); z-index: 99; outline: 0; }"+".file-input-name { margin-left: 8px; }"+"</style>";e("link[rel=stylesheet]").eq(0).before(t)})(jQuery)
