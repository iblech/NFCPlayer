/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */
package com.github.iblech.nfcplayer

import android.app.Activity
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import com.github.iblech.nfcplayer.record.ParsedNdefRecord

/**
 * Utility class for creating [ParsedNdefMessage]s.
 */
object NdefMessageParser {
    /** Parse an NdefMessage  */
    fun parse(message: NdefMessage): List<ParsedNdefRecord> {
        return getRecords(message.records)
    }

    fun getRecords(records: Array<NdefRecord>): List<ParsedNdefRecord> {
        val elements = mutableListOf<ParsedNdefRecord>()
        for (record in records) {
            elements.add(object : ParsedNdefRecord {
                override fun getView(
                    activity: Activity,
                    inflater: LayoutInflater,
                    parent: ViewGroup,
                    offset: Int
                ): View {
                    val text = inflater.inflate(R.layout.tag_text, parent, false) as TextView
                    text.text = String(record.payload)
                    return text
                }
            })
        }
        return elements
    }
}
