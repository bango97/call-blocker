package com.callblocker.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.callblocker.model.PatternType
import com.callblocker.viewmodel.AddRuleViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddRuleScreen(
    onBack: () -> Unit,
    vm: AddRuleViewModel = viewModel()
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New Block Rule") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    TextButton(
                        onClick = { vm.save { onBack() } },
                        enabled = vm.canSave
                    ) {
                        Text("Save")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Pattern type selector
            Text("Pattern Type", style = MaterialTheme.typography.labelLarge)
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                PatternType.entries.forEachIndexed { index, pt ->
                    SegmentedButton(
                        shape = SegmentedButtonDefaults.itemShape(index, PatternType.entries.size),
                        onClick = { vm.type = pt },
                        selected = vm.type == pt,
                        label = { Text(pt.displayName) }
                    )
                }
            }
            Text(
                vm.type.hint,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            HorizontalDivider()

            // Pattern input
            OutlinedTextField(
                value = vm.pattern,
                onValueChange = { vm.pattern = it },
                label = { Text("Pattern") },
                placeholder = { Text(vm.type.placeholder) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                singleLine = true,
                isError = vm.validationError != null,
                supportingText = {
                    val error = vm.validationError
                    if (error != null) {
                        Text(error, color = MaterialTheme.colorScheme.error)
                    } else if (vm.expansionCount > 1) {
                        Text("Matches ~${"%,d".format(vm.expansionCount)} numbers")
                    }
                },
                modifier = Modifier.fillMaxWidth()
            )

            // Optional label
            OutlinedTextField(
                value = vm.label,
                onValueChange = { vm.label = it },
                label = { Text("Label (optional)") },
                placeholder = { Text("e.g. Spam calls") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
