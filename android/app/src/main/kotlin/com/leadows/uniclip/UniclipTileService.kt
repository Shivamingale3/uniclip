package com.leadows.uniclip

import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.os.Build
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class UniclipTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    override fun onClick() {
        super.onClick()
        val tile = qsTile ?: return
        
        // Toggle state logic here. 
        // For now, let's just assume active means "syncing".
        // Real logic would involve communicating with the Flutter Service.
        // Simple toggle for visual feedback:
        val newState = if (tile.state == Tile.STATE_ACTIVE) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        
        tile.state = newState
        tile.label = if (newState == Tile.STATE_ACTIVE) "Auto Sync On" else "Sync Paused"
        tile.updateTile()
        
        // Broadcast intent to Flutter logic if needed
        // val intent = Intent("com.leadows.uniclip.TOGGLE_SYNC")
        // sendBroadcast(intent)
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        // Default to active for now
        if (tile.state == Tile.STATE_UNAVAILABLE) {
            tile.state = Tile.STATE_ACTIVE
            tile.label = "Auto Sync On"
        }
        tile.updateTile()
    }
}
