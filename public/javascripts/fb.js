var fmtPopup = undefined;
var fmtPopupName = 'fmtfblogin';
var fmtPopupParams =  'width=580,height=400,location=no,menubar=no,toolbar=no,scrollbars:auto';
var fbButtonState = 'idle'; // idle, busy or blocked (if it seems popup was denied)
var fbCallBackUrl = '';
  
function checkLoginOrCallFacebook(){
    if (fbButtonState == 'idle'){
        fbButtonState = 'busy'; 
        $(".facebook").css('background-repeat', 'repeat-y');
        paintFbButton(fbButtonState);
        FB.getLoginStatus(function(response) {
            var rememberMe = $('#user_session_remember_me').is(':checked');
            if (response.session && response.status && response.status == 'connected') { // fb says: logged in
                var authParams = { 'access_token' : response.session.access_token, 
                                    'token_expiry' : response.session.expires,
                                    'source' : 'facebook',
                                    'remember_me' : rememberMe
                                };
                if (fmtPopup){fmtPopup.close()};
                window.externalAuth(authParams);
            } else {
                var path = 'https://www.facebook.com/dialog/oauth?';
                var redirectUri = document.location.protocol + '//' + document.location.host 
                    + '/facebook_callback.html?fmt_remember=' + rememberMe;
                var queryParams = ['client_id=' + fmt_facebook_app_id,
                    'redirect_uri=' + redirectUri,
                    'scope=email',
                    'display=popup',
                    'response_type=token'];
                fbCallBackUrl = path + queryParams.join('&');                    
                fmtPopup = window.open(fbCallBackUrl, fmtPopupName, fmtPopupParams);
                // Can't usefully detect blocked popups on current Chrome: let the browser notify the user. Barely satisfactory.
                if (!fmtPopup || fmtPopup.closed || typeof fmtPopup.closed=='undefined'){
                    fbButtonState = 'blocked';
                } else {
                    fbButtonState = 'idle';
                    fmtPopup.focus();                        
                }
                paintFbButton(fbButtonState);
            }
        });
    } else if (fbButtonState == 'blocked') {
        if (fbCallBackUrl){
            fmtPopup = window.open(fbCallBackUrl, fmtPopupName, fmtPopupParams);  
        } else {
            // something goofy with the URL means it wasn't going to work anyway :-|
        }
        fbButtonState = 'idle';
    }
    if (fbButtonState == 'idle') {
        paintFbButton(fbButtonState);
    }
    return false;
}
    
function paintFbButton(state) {
    var bgPosY;
    switch (state){
        case 'busy':
            bgPosY = '-50px';
            break;
        case 'blocked':
            bgPosY = '-100px'; 
            break;
        default:
            bgPosY = '0px';
    }
    $(".facebook").css('background-position', '0px ' + bgPosY); 
}