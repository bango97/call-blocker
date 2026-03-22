package com.callblocker.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.callblocker.ui.screens.AddRuleScreen
import com.callblocker.ui.screens.RuleListScreen
import com.callblocker.ui.theme.CallBlockerTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CallBlockerTheme {
                val nav = rememberNavController()
                NavHost(nav, startDestination = "rules") {
                    composable("rules") {
                        RuleListScreen(onAddRule = { nav.navigate("add") })
                    }
                    composable("add") {
                        AddRuleScreen(onBack = { nav.popBackStack() })
                    }
                }
            }
        }
    }
}
