package com.callblocker.ui.screens

import android.app.Activity
import android.app.role.RoleManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.callblocker.model.BlockRule
import com.callblocker.model.PatternType
import com.callblocker.viewmodel.RuleListViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RuleListScreen(
    onAddRule: () -> Unit,
    vm: RuleListViewModel = viewModel()
) {
    val rules by vm.rules.collectAsState()
    val context = LocalContext.current
    var hasRole by remember { mutableStateOf(vm.hasScreeningRole) }

    // Role request launcher
    val roleRequest = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        val roleManager = context.getSystemService(RoleManager::class.java)
        rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            hasRole = result.resultCode == Activity.RESULT_OK
        }.also { launcher ->
            LaunchedEffect(Unit) {
                if (!hasRole && roleManager != null) {
                    launcher.launch(roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING))
                }
            }
        }
    } else null

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("Call Blocker") })
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onAddRule) {
                Icon(Icons.Default.Add, contentDescription = "Add rule")
            }
        }
    ) { padding ->
        LazyColumn(
            contentPadding = padding,
            modifier = Modifier.fillMaxSize()
        ) {
            item {
                StatusCard(hasRole = hasRole)
            }
            if (rules.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier.fillParentMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "No rules yet.\nTap + to add a block rule.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            } else {
                items(rules, key = { it.id }) { rule ->
                    RuleCard(
                        rule = rule,
                        onToggle = { vm.toggleEnabled(rule) },
                        onDelete = { vm.delete(rule) }
                    )
                }
            }
        }
    }
}

@Composable
private fun StatusCard(hasRole: Boolean) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (hasRole)
                MaterialTheme.colorScheme.primaryContainer
            else
                MaterialTheme.colorScheme.errorContainer
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(if (hasRole) "✅" else "⚠️")
            Text(
                if (hasRole)
                    "Call screening active"
                else
                    "Grant call screening permission to enable blocking",
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

@Composable
private fun RuleCard(
    rule: BlockRule,
    onToggle: () -> Unit,
    onDelete: () -> Unit
) {
    ListItem(
        headlineContent = {
            Text(rule.label.ifBlank { rule.pattern })
        },
        supportingContent = {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TypeChip(rule.type)
                Text(
                    rule.pattern,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        leadingContent = {
            Switch(checked = rule.isEnabled, onCheckedChange = { onToggle() })
        },
        trailingContent = {
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Delete")
            }
        }
    )
    HorizontalDivider()
}

@Composable
private fun TypeChip(type: PatternType) {
    val color = when (type) {
        PatternType.EXACT    -> MaterialTheme.colorScheme.primary
        PatternType.PREFIX   -> Color(0xFFE65100)
        PatternType.WILDCARD -> MaterialTheme.colorScheme.tertiary
    }
    Surface(
        shape = MaterialTheme.shapes.small,
        color = color.copy(alpha = 0.15f)
    ) {
        Text(
            type.displayName,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
            style = MaterialTheme.typography.labelSmall,
            color = color
        )
    }
}
