{_, $, Backbone, Marionette, win, nw } = require( '../common.coffee' )
{ PeerGraph } = require './PeerGraph.coffee' 

class module.exports.SettingsView extends Marionette.LayoutView
    className: 'settings-view'
    template: _.template """
        <div class="content">
            
            <p><strong>Pirate Chest</strong> is still a  work in progress so many settings are hardcoded, with time they will be extracted to this view to give users more fine grained control.</p>
            <p>For <strong>Documentation</strong> or to <strong>Report Bugs</strong> you can go to our github repo at: <a href="http://github.com/piratechest/piratechest">http://github.com/piratechest/piratechest</a>.</p>
            <div>
                <div class="localstorage">LocalStorage: <a href="#">Clear All</a></div>
            </div>
            <p class="local-node">Local node:
                <span class="local-id">???</span>@
                <span class="local-host">???</span>:
                <span class="local-port">???</span>
            </p>
            <h3>Seeds</h3>
            <div class="seeds"></div>
            <h3>Peers</h3>
            <div class="peers"></div>
            <div class="graph"></div>
        </div>
    """
    ui:
        localId: '.local-id'
        localHost: '.local-host'
        localPort: '.local-port'

    regions:
        peers: '.peers'
        seeds: '.seeds'
        graph: '.graph'

    events:
        'click a': 'openLink'
        'click .localstorage a': '_handleClearLocalStorage'

    initialize: ({@config, @torrrentClient, @lodestone}) ->

    onShow: ->
        @peerCollection = new Backbone.Collection()
        @peers.show( new PeerCollectionView( collection: @peerCollection ) )
        @seedCollection = new Backbone.Collection()
        @seeds.show( new PeerCollectionView( collection: @seedCollection ) )
        @lodestone.on 'update-peers', @_handlePeerChanges
        @_handlePeerChanges()
        @_handleSetSeeds()
        @lodestone.ping()

        @ui.localId.text( @lodestone.gossip.localPeer.id )
        @ui.localHost.text( @lodestone.gossip.localPeer.transport.host )
        @ui.localPort.text( @lodestone.gossip.localPeer.transport.port )


    onClose: ->
        @lodestone.off 'update-peers', @_handlePeerChanges

    _handleSetSeeds: =>
        for peer in @lodestone.gossip.seeds
            @seedCollection.add new Backbone.Model
                id: peer.id
                host: peer.transport.host
                port: peer.transport.port
                live: false

    _handlePeerChanges: =>
        console.log "Handle lodestone peer changes"
        @peerCollection.reset([])
        for peer in @lodestone.gossip.storage.livePeers()
            @peerCollection.add new Backbone.Model
                id: peer.id
                host: peer.transport.host
                port: peer.transport.port
                live: true

        for peer in @lodestone.gossip.storage.deadPeers()
            @peerCollection.add new Backbone.Model
                id: peer.id
                host: peer.transport.host
                port: peer.transport.port
                live: false

        @graph.show new PeerGraph
            nodes: @peerCollection.map (p) -> { name: p.get('id'), group: 1 }
            links: [ { source: 0, target: 1, value: 1 } ]


    openLink: (ev) ->
        nw.Shell.openExternal( ev.currentTarget.href );
        ev.preventDefault()
        false

    _handleClearLocalStorage: ->
        confirm = window.confirm "Are you sure you want to clear your localStorage?"
        window.localStorage.clear() if confirm


class PeerView extends Marionette.ItemView
    className: => "peer-view #{ if @model.get('live') then 'live' else '' }"
    template: _.template """
        <i class="icon-<%= live ? 'circle' : 'circle-blank' %>"></i>
        <span class="id"><%- id %></span> - <span class="host"><%- host %></span>:<span class="port"><%- port %></span>
    """


class PeerCollectionView extends Marionette.CollectionView
    className: 'peer-collection-view'
    childView: PeerView