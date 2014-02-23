angular.module("app.auth", ['firebase', 'ngCookies'])

# gives you access to an authenticated firebase url ($ref.base)
# the user's netid ($ref.netid) and the user's info ($ref.me)
.factory '$ref' ($cookies, $rootScope, $firebase)->
    refScope = $rootScope.$new()
    cookieData = JSON.parse($cookies.casInfo)
    netid = cookieData.netid
    firebase = new Firebase($PROCESS_ENV_FIREBASE)
    do
        error <- firebase.auth(cookieData.token)
        console.log("Login Failed!", error) if error
        firebase.child("users/#{netid}").update({exists: true})
        $firebase(firebase.child("users/#{netid}")).$bind(refScope, "me").then (unbind)->
            $rootScope.$broadcast('newuser') if not refScope.me.name?
    refScope.base = firebase
    refScope.netid = netid
    return refScope

# returns a function that takes a list of netid
# and returns an auto-updating list of who is online
.factory '$trackConnected' ($ref, $firebase)->
    myConnectionsRef = $ref.base.child "users/#{$ref.netid}/connections"
    connectedRef = $ref.base.child '.info/connected'
    connectedRef.on 'value' (snap)!->
        if (snap.val!)
            myConnectionsRef.push true
            con.onDisconnect!remove!
    return (netids)->
        obj = {}
        for netid in netids
            obj[netid] = $firebase($ref.base.child("users/#{netid}/connections"))
        return obj

# $group.name gives the currently selected group name
# $group.setGroup takes a group id to set as currently selected
# call $group.clearGroup when back on the group page
.factory '$group' ($ref)->
    result =
        name: null
        setGroup: (groupid)->
            result.name = $ref.base.child("groups/#{groupid}/name").val!
        clearGroup: -> result.name = null
    return result
